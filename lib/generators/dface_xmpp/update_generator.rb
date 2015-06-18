class DfaceXmpp::UpdateGenerator < Rails::Generators::Base
    source_root File.expand_path("../", __FILE__)
    def copy_initializer_file
      remove_file "config/initializers/dface_xmpp.rb"
      copy_file "dface_xmpp.rb", "config/initializers/dface_xmpp.rb"
    end
end