# frozen_string_literal: true

commit_id_file = Rails.root.join 'commit_id.txt'

Rails.application.commit_id = if File.exist? commit_id_file
                                File.read(commit_id_file).chomp
                              else
                                'N/A'
                              end
