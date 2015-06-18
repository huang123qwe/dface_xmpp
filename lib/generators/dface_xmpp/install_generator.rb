class DfaceXmpp::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("../", __FILE__)
  def create_initializer_file
      copy_file "dface_xmpp.rb", "config/initializers/dface_xmpp.rb"
  end
end