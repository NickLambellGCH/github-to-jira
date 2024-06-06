# frozen_string_literal: true

require "active_support/core_ext/object/blank"

# This is being used by the `exe/2-json-for-import` generator to
# generate the JSON issue for the importer (it's a different JSON than
# the one we need for REST API).
class Sin::Generator
  attr_reader :project_key
  attr_reader :issue
  attr_reader :comments
  attr_reader :status_map

  def initialize(project_key, issue, comments, status_map)
    @project_key = project_key
    @issue = issue
    @comments = comments
    @status_map = status_map
  end

  def automation_for_jira_user_id
    ENV.fetch("AUTOMATION_FOR_JIRA_USER_ID")
  end

  def assignee
    Sin::User.atlassian_id(self.issue.dig("assignee", "login"))
  end

  def reporter
    Sin::User.atlassian_id(self.issue.dig("user", "login")) || self.automation_for_jira_user_id
  end

  def status(external_id)
    mapped_status = self.status_map[external_id]
    return mapped_status if mapped_status

    self.issue["state"] == "open" ? "Imported" : "Complete"
  end

  def resolution
    unless self.issue["state"] == "open"
      self.issue["state_reason"] == "not_planned" ? "Won't Do" : "Done"
    end
  end

  def labels
    (self.issue["labels"] || [])
      .map { |x| x["name"].downcase.gsub(" ", "-") }
      .compact
      .presence
  end

  def to_jira(repo_name)
    comments_value = self.comments.map do |comment|
      id = comment["id"]
      {
        author: Sin::User.atlassian_id(comment.dig("user", "login")) || self.automation_for_jira_user_id,
        created: Time.parse(comment["created_at"]).utc.iso8601,
        externalId: id,
        body: "GHCID:#{id}"
      }
    end

    external_id = "#{repo_name}-#{self.issue["number"]}"

    {
      externalId: external_id,
      created: Time.parse(self.issue["created_at"]).utc.iso8601,
      updated: Time.parse(self.issue["updated_at"]).utc.iso8601,
      summary: self.issue["title"],
      reporter: self.reporter,
      assignee: self.assignee,
      issueType: "Task",
      status: self.status(external_id),
      resolution: self.resolution,
      labels: self.labels,
      components: [
        repo_name
      ],
      customFieldValues: [
        {
          fieldName: "GitHub URL",
          fieldType: "com.atlassian.jira.plugin.system.customfieldtypes:url",
          value: self.issue["html_url"]
        }
      ],
      comments: comments_value
    }.compact
  end
end
