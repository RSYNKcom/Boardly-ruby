# frozen_string_literal: true

require_relative "../util/project"

module Boardly
  module Features
    # Auto-assign by label: a CODEOWNERS-style map from ticket label → GitHub
    # assignees. When a ticket in one of `only_statuses` (default "Ready") is
    # still unassigned and carries a mapped label, assign the configured users.
    # A ticket matching no rule is left untouched; an already-assigned ticket is
    # never overridden. Pairs naturally with SprintStart.
    module AutoAssign
      module_function

      def run(ctx)
        cfg = ctx.cfg
        graph = ctx.graph
        feat = cfg.features[:auto_assign]
        rules = feat[:rules]
        return if rules.empty? # opt-in: nothing to do without a mapping

        only = feat[:only_statuses].map(&:downcase)

        graph.items.each do |item|
          next unless item.content # draft cards have no issue to assign
          next if Util::Project.done?(item, cfg)

          status = Util::Project.status_of(item, cfg)
          next if !only.empty? && !(status && only.include?(status.downcase))

          # Only assign tickets nobody owns yet — never override a human's choice.
          next unless Array(item.content.assignees).empty?

          item_labels = Array(item.content.labels).map(&:downcase)
          to_assign = []
          rules.each do |rule|
            to_assign.concat(rule[:assignees]) if item_labels.include?(rule[:label].to_s.downcase)
          end
          to_assign.uniq!
          next if to_assign.empty?

          c = item.content
          label = "##{c.number} #{c.title}"
          ctx.audit.record("autoAssign", "assign", label, "→ #{to_assign.map { |a| "@#{a}" }.join(", ")}")
          ctx.client.add_assignees(c.repo_owner, c.repo_name, c.number, to_assign) unless ctx.dry_run
        end
      end
    end
  end
end
