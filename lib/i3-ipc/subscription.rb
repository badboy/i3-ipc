require 'eventmachine'

module I3
  module Subscription
    extend self

    class SubscriptionConnection < EM::Connection
      def self.connect(subscription_list, socket_path=I3::IPC::SOCKET_PATH, &blk)
        new_klass = Class.new(self)
        new_klass.send(:define_method, :initialize) do
          @subscription_list = subscription_list
          @handler = blk
        end
        EM.connect socket_path, new_klass
      end

      # send subscription to i3
      def post_init
        send_data I3::IPC.format(I3::IPC::MESSAGE_TYPE_SUBSCRIBE,
                                 @subscription_list.to_json)
      end

      # receive data, parse it and pass on to the user-defined handler
      def receive_data(data)
        @handler.call(self, *I3::IPC.parse_response(data)) if @handler
      end
    end

    def subscribe(subscription_list, socket_path=I3::IPC::SOCKET_PATH, &blk)
      EM.run do
        SubscriptionConnection.connect(subscription_list,
                                       socket_path, &blk)
      end
    end
  end
end
