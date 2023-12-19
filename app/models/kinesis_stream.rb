# frozen_string_literal: true

class KinesisStream
  def initialize
    @comment_events = []
    @classification_events = []
    @classification_user_groups = []
  end

  def create_events(payload)
    receive(payload)

    # Because ERAS is one of the ONLY receiving apps that receives from kinesis and BULK UPSERTS (feature of Rails 6+), it has caught duplicates on payload from kinesis stream
    # See: https://zooniverse-27.sentry.io/issues/4717869260/?project=4506117954011141&query=is%3Aunresolved&referrer=issue-stream&statsPeriod=14d&stream_index=3
    # EVEN THOUGH de-duping the payload by id before upserting should resolve issues with ERAS, (since ERAS only cares about counting the classification/comment once),
    # UNFORTUNATELY, there are other apps (eg. Caesar, Tove) that rely on the kinesis stream and where duplicates in payload may affect results.
    # Since ERAS is one of the only places we can catch this error (because of how it can bulk upsert), the team has decided to log the error to Sentry when the duplicates in payload occurs
    # and also log the payload to Sentry.
    ## Should note that this duplicate error has been seen before:
    ## SEE: https://github.com/zooniverse/zoo-stats-api-graphql/pull/128
    ## ALSO NOTING: THIS CATCH, LOG, DEDUPE AND TRY UPSERTING AGAIN TO DB SITUATION IS TEMPORARY AND ONLY USED
    ## TO SEE WHAT THE DUPES IN THE KINESIS PAYLOAD ARE.
    ## ONE MORE NOTE: per Kinesis docs, it is VERY possible for Kinesis stream to send duplicates and
    ## the recommendation of AWS is to appropriately handle process records.
    ## SEE: https://docs.aws.amazon.com/streams/latest/dev/kinesis-record-processor-duplicates.html

    upsert_comments unless @comment_events.empty?
    upsert_classifications unless @classification_events.empty?
    upsert_classification_user_groups unless @classification_user_groups.empty?
  end

  def upsert_comments
    CommentEvent.upsert_all(@comment_events, unique_by: %i[comment_id event_time])
  rescue StandardError => e
    crumb = Sentry::Breadcrumb.new(
      category: 'upsert_error_in_comments',
      message: 'Comment Events Upsert Error',
      data: {
        payload: @comment_events,
        error_message: e.message
      },
      level: 'warning'
    )
    Sentry.add_breadcrumb(crumb)
    if e.message.include?('ON CONFLICT DO UPDATE command cannot affect row a second time')
      @comment_events = @comment_events.uniq { |comment| comment[:comment_id] }
      retry
    end
  end

  def upsert_classifications
    ClassificationEvent.upsert_all(@classification_events, unique_by: %i[classification_id event_time])
  rescue StandardError => e
    crumb = Sentry::Breadcrumb.new(
      category: 'upsert_error_in_classifications',
      message: 'Classification Events Upsert Error',
      data: {
        payload: @classification_events,
        error_message: e.message
      },
      level: 'warning'
    )
    Sentry.add_breadcrumb(crumb)
    if e.message.include?('ON CONFLICT DO UPDATE command cannot affect row a second time')
      @classification_events = @classification_events.uniq { |classification| classification[:classification_id] }
      retry
    end
  end

  def upsert_classification_user_groups
    ClassificationUserGroup.upsert_all(@classification_user_groups.flatten, unique_by: %i[classification_id event_time user_group_id user_id])
  rescue StandardError => e
    crumb = Sentry::Breadcrumb.new(
      category: 'upsert_error_in_classifications_user_groups',
      message: 'Classification User Groups Upsert Error',
      data: {
        payload: @classification_user_groups,
        error_message: e.message
      },
      level: 'warning'
    )
    Sentry.add_breadcrumb(crumb)
    if e.message.include?('ON CONFLICT DO UPDATE command cannot affect row a second time')
      @classification_user_groups = @classification_user_groups.uniq { |cug| [cug[:classification_id], cug[:user_group_id]] }
      retry
    end
  end

  def receive(payload)
    ActiveRecord::Base.transaction do
      payload.each do |event|
        event_data = event.fetch('data')
        prepared_payload = StreamEvents.from(event).process
        @comment_events << prepared_payload if StreamEvents.comment_event?(event)

        next unless StreamEvents.classification_event?(event)

        @classification_events << prepared_payload
        add_classification_user_groups(event_data) if StreamEvents.user_group_ids?(event_data)
      end
    end
  end

  private

  def add_classification_user_groups(event_data)
    user_group_ids = event_data.fetch('metadata').fetch('user_group_ids')
    user_group_ids.uniq.each do |user_group_id|
      @classification_user_groups << StreamEvents::ClassificationUserGroup.new(event_data, user_group_id).process
    end
  end
end
