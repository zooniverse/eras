# frozen_string_literal: true

require 'pg'
require '../config/environment'

class PanoptesMembershipClient
  def user_ids_not_in_user_group(user_group_id, domain_formats)
    conn.exec(
      "SELECT id FROM users
    WHERE email ILIKE ANY(STRING_TO_ARRAY('#{domain_formats.join(',')}', ','))
    AND id NOT IN (SELECT user_id FROM memberships where user_group_id=#{user_group_id})
    "
    ).entries.map { |res| res['id'].to_i }
  end

  def insert_memberships(user_group_id, user_ids)
    memberships_to_create = user_memberships(user_group_id, user_ids)

    member_creation_sql_query = memberships_insert_query(memberships_to_create)

    conn.exec_params(member_creation_sql_query, memberships_to_create.flatten)
  end

  private

  def conn
    @conn ||= PG.connect(Rails.application.credentials.panoptes_db_uri, sslmode: 'require')
  end

  def user_memberships(user_group_id, user_ids)
    memberships_to_create = []
    user_ids.each do |user_id|
      # membership in array order: user_id, user_group_id, state, roles
      membership = [
        user_id,
        user_group_id,
        0,
        '{"group_member"}'
      ]
      memberships_to_create << membership
    end
    memberships_to_create
  end

  def memberships_insert_query(memberships_to_create)
    # Values is part of sql query will look like ($1, $2, $3, $4), ($5, $6, $7, $8), ..etc..
    values = Array.new(memberships_to_create.length) do |i|
      "($#{(4 * i) + 1}, $#{(4 * i) + 2}, $#{(4 * i) + 3}, $#{(4 * i) + 4})"
    end.join(',')
    "INSERT INTO memberships (user_id, user_group_id, state, roles) VALUES #{values}"
  end
end
