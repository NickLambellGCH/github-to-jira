# frozen_string_literal: true

require "singleton"
require "octokit"

# :nodoc:
class Sin::Github
  include Singleton

  def issue(repo, number)
    self.client.issue(repo, number)
  end

  def issues(repo, state: :open)
    self.client.list_issues(repo, state: state.to_s)
  end

  def comments(repo, number)
    self.client.issue_comments(repo, number)
  end

  def organization
    ENV.fetch("GITHUB_ORG")
  end

  def organization_members
    self.client.organization_members(self.organization)
  end

  def organization_repositories
    self.client.organization_repositories(self.organization)
  end

  def rate_limit
    self.client.rate_limit
  end

  def client
    @client ||= begin
      c = Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))
      c.auto_paginate = true
      c
    end
  end
end
