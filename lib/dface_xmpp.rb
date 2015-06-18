require "dface_xmpp/version"

module DfaceXmpp
  $xmpp_ips ||= []
  $xmpp_ip_seq=rand($xmpp_ips.size)
  
  def self.cur_xmpp_ip
    $xmpp_ips[$xmpp_ip_seq]
  end
  
  def self.next_xmpp_ip
    $xmpp_ip_seq += 1
    $xmpp_ip_seq = 0 if $xmpp_ip_seq >= $xmpp_ips.size
    $xmpp_ips[$xmpp_ip_seq]
  end
  
  def self.get(path, headers={}, &block)
    begin 
      RestClient.get("http://#{cur_xmpp_ip}:5280/#{path}", headers, &block)
    rescue Errno::ECONNREFUSED => e
      RestClient.get("http://#{next_xmpp_ip}:5280/#{path}", headers, &block)
      #TODO: 失败处理
    end
  end
  
  def self.post(path, payload, headers={}, &block)
    begin 
      RestClient.post("http://#{cur_xmpp_ip}:5280/#{path}", payload, headers, &block)
    rescue Errno::ECONNREFUSED => e
      RestClient.post("http://#{next_xmpp_ip}:5280/#{path}", payload, headers, &block)
      #TODO: 失败处理
    end
  end
  
  def self.normal_chat(from,to,msg, id=nil, attrs="", ext="")
    msg2 = CGI.escapeHTML(msg)
    mid = id.nil?? $uuid.generate : id
    "<message id='#{mid}' to='#{to}@dface.cn' from='#{from}@dface.cn' type='normal' #{escape(attrs)}><body>#{msg2}</body>#{escape_amp(ext)}</message>"
  end
  
  def self.send_normal(from,to,msg,id=nil, attrs="", ext="")
    post("rest", Xmpp.normal_chat(from,to,msg,id,attrs,ext)) 
  end

  def self.chat(from,to,msg, id=nil, attrs="", ext="")
    msg2 = CGI.escapeHTML(msg)
    mid = id.nil?? $uuid.generate : id
    attrs += " NOLOG='1' " if (from.to_s == $gfuid || from.to_s == 'scoupon' || msg[0]==':') && attrs.index("NOLOG").nil?
    #TODO: 服务器端发送消息的回执不需要会给模拟发起的用户
    "<message id='#{mid}' to='#{to}@dface.cn' from='#{from}@dface.cn' type='chat' #{escape(attrs)}><body>#{msg2}</body><x xmlns='jabber:x:event'><displayed/></x>#{escape_amp(ext)}</message>"
  end
  
  #发送个人聊天消息
  def self.send_chat(from,to,msg,id=nil, attrs="", ext="")
    post("rest", Xmpp.chat(from,to,msg,id,attrs,ext)) 
  end
  
  def self.gchat(from,to,msg, id=nil, attrs="", ext="")
    msg2 = CGI.escapeHTML(msg)
    mid = id.nil?? $uuid.generate : id
    "<message id='#{mid}' to='#{to}@dface.cn' from='#{from.to_i}@c.dface.cn' type='groupchat' #{escape(attrs)}><body>#{msg2}</body>#{escape_amp(ext)}</message>"
  end 

  #发送单聊回执
    def self.send_receipt(from, to, mid)
      receipt = "<message id='#{mid.succ}' to='#{to}@dface.cn' from='#{from}@dface.cn'><x xmlns='jabber:x:event'><delivered/><id>#{mid}</id></x></message>"
      RestClient.post("http://42.121.0.192:5280/rest", receipt)
    end
  
  #在聊天室发送系统消息
  def self.send_gchat(from,to,msg, id=nil, attrs="", ext="")
    mid = id.nil?? $uuid.generate : id
    post("rest", Xmpp.gchat(from,to,msg,mid,attrs,ext)) 
    begin
      #这类消息没有发送者，目前同步到客户端有问题
      #gchat = Gchat.new(sid: from.to_i, uid: from, tid:to, mid: mid, txt: msg)
      #gchat.save
    rescue Exception => e
      Xmpp.error_notify("聊天消息保存失败#{e}")
    end
  end

  def self.gchat2(from,room,to,msg, id=nil, attrs="", ext="")
    msg2 = CGI.escapeHTML(msg)
    mid = id.nil?? $uuid.generate : id
    "<message id='#{mid}' to='#{to}@dface.cn' from='#{room.to_i}@c.dface.cn/#{from}' type='groupchat' #{escape(attrs)}><body>#{msg2}</body>#{escape_amp(ext)}</message>"
  end 
  
  #在聊天室以特定用户身份发消息
  def self.send_gchat2(from,room,to,msg, id=nil, attrs="", ext="")
    return "消息：#{msg}" if ENV["RAILS_ENV"] != "production"
    mid = id.nil?? $uuid.generate : id
    post("rest", Xmpp.gchat2(from,room,to,msg,mid,attrs,ext))
    begin
      gchat = Gchat.new(sid: room, uid: from, tid:to, mid: mid, txt: msg)
      gchat.save
    rescue Exception => e
      Xmpp.error_notify("聊天消息保存失败#{e}")
    end
  end
  
  def self.send_gchat2_no_log(from,room,to,msg, id=nil, attrs="", ext="")
    return "消息：#{msg}" if ENV["RAILS_ENV"] != "production"
    post("rest", Xmpp.gchat2(from,room,to,msg,id,attrs,ext))
  end

  def self.send_link_gchat(from,room,to,msg,link=nil, id=nil)
    return Xmpp.send_gchat2(from,room,to,msg,id) if link.nil?
    attrs = " NOLOG='1'  url='#{link}' " 
    ext = "<x xmlns='dface.url'>#{link}</x>"
    Xmpp.send_gchat2(from,room,to,msg,id ,attrs, ext)
  end
  
  def self.error_notify(str, uid=$yuanid)
    return unless Rails.env=="production"
    Rails.cache.fetch("XMPP_ERR#{str[0,10]}", :expires_in => 30.minutes) do
      Rails.cache.fetch("XMPP_ERR#{str[0,20]}", :expires_in => 6.hours) do
        Resque.enqueue(XmppMsg, $gfuid,uid,str)
        "1"
      end
    end
  end
  
  def self.escape(str)
    return "" if str.nil?
    #return CGI.escapeHTML(str)
    s = str.gsub("&", "&amp;")
    s.gsub!("<", "&lt;")
    s.gsub!(">", "&gt;")
    s
  end
  
  def self.escape_amp(str)
    return "" if str.nil?
    str.gsub("&", "&amp;")
  end
  
  def self.lua_exec(uid,func)
    iosurl = "http://www.dface.cn/lua/ios/#{func}.lua"
    androidurl = "http://www.dface.cn/lua/android/#{func}.lua"    
    attrs = " NOLOG='1'  url='#{iosurl}' "
    ext = "<x xmlns='dface.url'>#{androidurl}</x>"
    Xmpp.send_normal($gfuid, uid, "lua","RPC#{func}",attrs, ext )
  end
  
  def self.test
    cur_ip = nil
    begin
      $xmpp_ips.each do |ip|
        cur_ip = ip
        RestClient.post("http://#{ip}:5280/api/room", 
          :roomid  => "4928288" , :message=> "测试一下" ,
          :uid => "502e6303421aa918ba000001", :mid => $uuid.generate, :log => 0) 
      end
    rescue Exception => e
      raise cur_ip
    end
  end
  
  def self.test_server_msg(uid)
    100.times {|x| Xmpp.send_chat($gfuid,uid,x.to_s);sleep 1}
  end
  
  def self.test_and_msg
    txt = "[img:52aa8c9320f31890f7000026]浦靠谱在NOW PUB&SALOON分享了一张图片,温暖午餐"
    id = "FEED#{Time.now.to_i}"
    attr = " NOLOG='1' NOPUSH='1' SID='6411140' SNAME='NOW PUB&SALOON' "
    ext = "<x xmlns='dface.shop' SID='6411140' SNAME='NOW PUB&SALOON' ></x>"
    Xmpp.send_chat($gfuid,User.first.id,txt,id,attr,ext)
  end
end
