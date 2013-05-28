module Collector
  module Components
    CLOUD_CONTROLLER_COMPONENT = "CloudController".freeze
    DEA_COMPONENT = "DEA".freeze
    HEALTH_MANAGER_COMPONENT = "HealthManager".freeze
    ROUTER_COMPONENT = "Router".freeze

    # services components
    MYSQL_PROVISIONER = "MyaaS-Provisioner".freeze
    MYSQL_NODE = "MyaaS-Node".freeze

    PGSQL_PROVISIONER = "AuaaS-Provisioner".freeze
    PGSQL_NODE = "AuaaS-Node".freeze

    MONGODB_PROVISIONER = "MongoaaS-Provisioner".freeze
    MONGODB_NODE = "MongoaaS-Node".freeze

    NEO4J_PROVISIONER = "Neo4jaaS-Provisioner".freeze
    NEO4J_NODE = "Neo4jaaS-Node".freeze

    RABBITMQ_PROVISIONER = "RMQaaS-Provisioner".freeze
    RABBITMQ_NODE = "RMQaaS-Node".freeze

    REDIS_PROVISIONER = "RaaS-Provisioner".freeze
    REDIS_NODE = "RaaS-Node".freeze

    VBLOB_PROVISIONER = "VBlobaaS-Provisioner".freeze
    VBLOB_NODE = "VBlobaaS-Node".freeze

    SERIALIZATION_DATA_SERVER = "SerializationDataServer".freeze

    BACKUP_MANAGER = "BackupManager".freeze

    CORE_COMPONENTS = Set.new([CLOUD_CONTROLLER_COMPONENT, DEA_COMPONENT,
      HEALTH_MANAGER_COMPONENT, ROUTER_COMPONENT]).freeze
    SERVICE_COMPONENTS = Set.new([MYSQL_PROVISIONER, MYSQL_NODE,
      PGSQL_PROVISIONER, PGSQL_NODE,
      MONGODB_PROVISIONER, MONGODB_NODE,
      NEO4J_PROVISIONER, NEO4J_NODE,
      RABBITMQ_PROVISIONER, RABBITMQ_NODE,
      REDIS_PROVISIONER, REDIS_NODE,
      VBLOB_PROVISIONER, VBLOB_NODE]).freeze
    SERVICE_AUXILIARY_COMPONENTS = Set.new([SERIALIZATION_DATA_SERVER,
      BACKUP_MANAGER]).freeze

    # Generates the common tags used for generating common
    # (memory, health, etc.) metrics.
    #
    # @param [String] type the job type
    # @return [Hash<Symbol, String>] tags for this job type
    def self.get_job_tags(type)
      tags = {}
      if CORE_COMPONENTS.include?(type)
        tags[:role] = "core"
      elsif SERVICE_COMPONENTS.include?(type)
        tags[:role] = "service"
      elsif SERVICE_AUXILIARY_COMPONENTS.include?(type)
        tags[:role] = "service"
      end
      tags
    end
  end
end