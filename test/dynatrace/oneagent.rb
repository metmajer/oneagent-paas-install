module Dynatrace
  class OneAgent
    BITNESS_32 = 32
    BITNESS_64 = 64

    def self.get_monitored_process_cmd(cmd, bitness = Dynatrace::OneAgent::BITNESS_64)
      return "/tmp/dynatrace/oneagent/dynatrace-agent#{bitness}.sh sh -c '#{cmd}'"
    end

    class Apache
      def self.get_monitored_process_log()
        return "/tmp/dynatrace/oneagent/log/apache/ruxitagent_Apache_Web_Server_apache2_*.log"
      end
    end

    class Java
      def self.get_monitored_process_log()
        date = Time.now.strftime('%Y-%m-%d')
        return "/tmp/dynatrace/oneagent/log/process/ruxitagentproc_#{date}.log"
      end
    end

    class NGINX
      def self.get_monitored_process_log()
        return "/tmp/dynatrace/oneagent/log/nginx/ruxitagent_startup_nginx_*.log"
      end
    end

    class PHP
      def self.get_monitored_process_log()
        return "/tmp/dynatrace/oneagent/log/php/ruxitagent_Apache_Web_Server_apache2_*.log"
      end
    end

    class SpringBootMavenPluginRunner
      def self.get_monitored_process_log()
        return "/tmp/dynatrace/oneagent/log/java/ruxitagent_org.apache.maven.wrapper.MavenWrapperMain_*.log"
      end
    end
  end
end