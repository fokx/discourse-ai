# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseAi::AiBot::Tools::GithubFileContent do
  let(:tool) do
    described_class.new(
      {
        repo_name: "discourse/discourse-ai",
        file_paths: %w[lib/database/connection.rb lib/ai_bot/tools/github_pull_request_diff.rb],
        branch: "8b382d6098fde879d28bbee68d3cbe0a193e4ffc",
      },
    )
  end

  let(:llm) { DiscourseAi::Completions::Llm.proxy("open_ai:gpt-4") }

  describe "#invoke" do
    before do
      stub_request(
        :get,
        "https://api.github.com/repos/discourse/discourse-ai/contents/lib/database/connection.rb?ref=8b382d6098fde879d28bbee68d3cbe0a193e4ffc",
      ).to_return(
        status: 200,
        body: { content: Base64.encode64("content of connection.rb") }.to_json,
      )

      stub_request(
        :get,
        "https://api.github.com/repos/discourse/discourse-ai/contents/lib/ai_bot/tools/github_pull_request_diff.rb?ref=8b382d6098fde879d28bbee68d3cbe0a193e4ffc",
      ).to_return(
        status: 200,
        body: { content: Base64.encode64("content of github_pull_request_diff.rb") }.to_json,
      )
    end

    it "retrieves the content of the specified GitHub files" do
      result = tool.invoke(nil, llm)
      expected = {
        file_contents:
          "File Path: lib/database/connection.rb:\ncontent of connection.rb\nFile Path: lib/ai_bot/tools/github_pull_request_diff.rb:\ncontent of github_pull_request_diff.rb",
      }

      expect(result).to eq(expected)
    end
  end

  describe ".signature" do
    it "returns the tool signature" do
      signature = described_class.signature
      expect(signature[:name]).to eq("github_file_content")
      expect(signature[:description]).to eq("Retrieves the content of specified GitHub files")
      expect(signature[:parameters]).to eq(
        [
          {
            name: "repo_name",
            description: "The name of the GitHub repository (e.g., 'discourse/discourse')",
            type: "string",
            required: true,
          },
          {
            name: "file_paths",
            description: "The paths of the files to retrieve within the repository",
            type: "array",
            item_type: "string",
            required: true,
          },
          {
            name: "branch",
            description: "The branch or commit SHA to retrieve the files from (default: 'main')",
            type: "string",
            required: false,
          },
        ],
      )
    end
  end
end
