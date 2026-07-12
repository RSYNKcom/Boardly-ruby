# frozen_string_literal: true

require "time"
require_relative "../util/project"

module Boardly
  module Features
    # Sprint runway warning.
    #
    # GitHub never creates iterations automatically — the iteration list is a
    # fixed, manually-managed set. When the current sprint ends and nothing is
    # planned beyond it, rollover/sprint-start have no iteration to act on. This
    # feature is read-only: it counts how many iterations start in the future and
    # warns (job summary + Action annotation) when that runway drops below
    # `min_future`, so someone adds the next sprint before the board runs dry.
    module SprintRunway
      module_function

      def run(ctx)
        field = Util::Project.require_field(ctx.graph, ctx.cfg.fields[:iteration], "sprintRunway")
        min_future = ctx.cfg.features[:sprint_runway][:min_future]

        now = ctx.now
        iterations = field.iterations || []
        planned = iterations.select { |it| Time.iso8601("#{it.start_date}T00:00:00Z") > now }

        if planned.length >= min_future
          puts "sprintRunway: #{planned.length} future iteration(s) planned (min #{min_future}) — OK."
          return
        end

        have = planned.empty? ? "no future iterations are planned" : "only #{planned.length} future iteration(s) planned"
        msg = %(Sprint runway low: #{have} (want at least #{min_future}). Add the next sprint in the "#{field.name}" field settings — GitHub does not create iterations automatically.)

        ctx.audit.record("sprintRunway", "warn-runway", field.name, msg)
        puts "::warning::sprintRunway: #{msg}"
      end
    end
  end
end
