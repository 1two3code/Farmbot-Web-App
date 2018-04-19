module Configs
  class Update < Mutations::Command
    HOTFIX = [ :encoder_scaling_x, :encoder_scaling_y, :encoder_scaling_z ]
    BAD    = 56
    GOOD   = 5556

    required do
      duck :target, methods: [:update_attributes!]
      duck :update_attrs, methods: [:deep_symbolize_keys]
    end

    def execute
      target.update_attributes!(sliced_attrs)
      HOTFIX.map do |attr| # TODO: Delete this later on. August ish?
        target.update_attributes!(attr => GOOD) if target.try(attr) == BAD
      end
      target
    end

    def sliced_attrs
      whitelist = target.class.column_names.map(&:to_sym)
      updates   = update_attrs
        .deep_symbolize_keys
        .except(:device_id, :id, :created_at)
      updates.slice(*whitelist)
    end
  end
end
