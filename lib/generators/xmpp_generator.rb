class XmppGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/xmpp.rb", "# Add initialization content here"
  end
end