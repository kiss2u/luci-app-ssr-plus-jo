-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Copyright (C) 2018 lean <coolsnowwolf@gmail.com> github.com/coolsnowwolf
-- Licensed to the public under the GNU General Public License v3.

local m, s, sec, o, kcp_enable
local shadowsocksr = "shadowsocksr"
local gfw_count=0
local ad_count=0
local ip_count=0
local gfwmode=0

if nixio.fs.access("/etc/dnsmasq.ssr/gfw_list.conf") then
gfwmode=1		
end

local uci = luci.model.uci.cursor()

local sys = require "luci.sys"

if gfwmode==1 then 
 gfw_count = tonumber(sys.exec("cat /etc/dnsmasq.ssr/gfw_list.conf | wc -l"))/2
 if nixio.fs.access("/etc/dnsmasq.ssr/ad.conf") then
  ad_count=tonumber(sys.exec("cat /etc/dnsmasq.ssr/ad.conf | wc -l"))
 end
end
 
if nixio.fs.access("/etc/china_ssr.txt") then 
 ip_count = sys.exec("cat /etc/china_ssr.txt | wc -l")
end


m = Map(shadowsocksr)

local server_table = {}
local encrypt_methods = {
	"none",
	"table",
	"rc4",
	"rc4-md5-6",
	"rc4-md5",
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"aes-128-ctr",
	"aes-192-ctr",
	"aes-256-ctr",	
	"bf-cfb",
	"camellia-128-cfb",
	"camellia-192-cfb",
	"camellia-256-cfb",
	"cast5-cfb",
	"des-cfb",
	"idea-cfb",
	"rc2-cfb",
	"seed-cfb",
	"salsa20",
	"chacha20",
	"chacha20-ietf",
}

local protocol = {
	"origin",
	"verify_deflate",		
	"auth_sha1_v4",
	"auth_aes128_sha1",
	"auth_aes128_md5",
	"auth_chain_a",
	"auth_chain_b",
	"auth_chain_c",
	"auth_chain_d",
	"auth_chain_e",
	"auth_chain_f",
}

obfs = {
	"plain",
	"http_simple",
	"http_post",
	"random_head",	
	"tls1.2_ticket_auth",
}

local raw_mode = {
	"faketcp",
	"udp",
	"icmp",
}

local seq_mode = {
	"0",
	"1",
	"2",
	"3",
	"4",
}

local cipher_mode = {
	"none",
	"xor",
	"aes128cbc",
}

local auth_mode = {
	"none",
	"simple",
	"md5",
	"crc32",
}

local speeder_mode = {
	"0",
	"1",
}

uci:foreach(shadowsocksr, "servers", function(s)
	if s.alias then
		server_table[s[".name"]] = "[%s]:%s" %{string.upper(s.type), s.alias}
	elseif s.server and s.server_port then
		server_table[s[".name"]] = "[%s]:%s:%s" %{string.upper(s.type), s.server, s.server_port}
	end
end)


local key_table = {}   
for key,_ in pairs(server_table) do  
    table.insert(key_table,key)  
end 

table.sort(key_table)
m:section(SimpleSection).template  = "shadowsocksr/status1"
-- [[ Global Setting ]]--
s = m:section(TypedSection, "global", translate("Global Setting"))
s.anonymous = true

o = s:option(ListValue, "global_server", translate("Global Server"))
o:value("nil", translate("Disable"))
for k, v in pairs(server_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

o = s:option(ListValue, "udp_relay_server", translate("Game Mode UDP Server"))
o:value("", translate("Disable"))
o:value("same", translate("Same as Global Server"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end


o = s:option(ListValue, "threads", translate("Multi Threads Option"))
o:value("0", translate("Auto Threads"))
o:value("1", translate("1 Thread"))
o:value("2", translate("2 Threads"))
o:value("4", translate("4 Threads"))
o:value("8", translate("8 Threads"))
o.default = "0"
o.rmempty = false


o = s:option(ListValue, "run_mode", translate("Running Mode"))
o:value("gfw", translate("GFW List Mode"))
o:value("router", translate("IP Route Mode"))
o:value("routers", translate("Oversea IP Route Mode"))
o:value("oversea", translate("Oversea GFW List Mode"))
o:value("all", translate("Global Mode"))
o.default = gfw


o = s:option(ListValue, "pdnsd_enable", translate("Resolve Dns Mode"))
o:value("0", translate("Use Local DNS Service listen port 5335"))
o:value("1", translate("Use Pdnsd tcp query and cache"))
o:value("2", translate("Use Pdnsd udp query and cache"))
if nixio.fs.access("/usr/bin/dnsforwarder") then
o:value("3", translate("Use dnsforwarder tcp query and cache"))
o:value("4", translate("Use dnsforwarder udp query and cache"))
end
if nixio.fs.access("/usr/bin/dnscrypt-proxy") then
o:value("5", translate("Use dnscrypt-proxy query and cache"))
end
if nixio.fs.access("/usr/bin/chinadns") then
o:value("6", translate("Use chinadns query and cache"))
end

o.default = 1

o = s:option(ListValue, "chinadns_enable", translate("Chiadns Resolve Dns Mode"))
o:value("0", translate("Use Local DNS Service"))
o:value("1", translate("Use Pdnsd tcp query and cache"))
o:value("2", translate("Use Pdnsd udp query and cache"))
if nixio.fs.access("/usr/bin/dnsforwarder") then
o:value("3", translate("Use dnsforwarder tcp query and cache"))
o:value("4", translate("Use dnsforwarder udp query and cache"))
end
if nixio.fs.access("/usr/bin/dnscrypt-proxy") then
o:value("5", translate("Use dnscrypt-proxy query and cache"))
end

if nixio.fs.access("/usr/sbin/smartdns") then
o:value("6", translate("Use smartdns query and cache"))
end

if nixio.fs.access("/usr/sbin/https_dns_proxy") then
o:value("7", translate("Use https_dns_proxy query and cache"))
end
o.default = 1
o:depends("pdnsd_enable", "6")

o = s:option(Value, "tunnel_forward", translate("Anti-pollution DNS Server"))
o:value("0.0.0.0:53", translate("Using System Default DNS"))
o:value("0.0.0.0:5333", translate("Using acceleration center DNS"))
o:value("8.8.4.4:53", translate("Google Public DNS (8.8.4.4)"))
o:value("8.8.8.8:53", translate("Google Public DNS (8.8.8.8)"))
o:value("208.67.222.222:53", translate("OpenDNS (208.67.222.222)"))
o:value("208.67.220.220:53", translate("OpenDNS (208.67.220.220)"))
o:value("209.244.0.3:53", translate("Level 3 Public DNS (209.244.0.3)"))
o:value("209.244.0.4:53", translate("Level 3 Public DNS (209.244.0.4)"))
o:value("4.2.2.1:53", translate("Level 3 Public DNS (4.2.2.1)"))
o:value("4.2.2.2:53", translate("Level 3 Public DNS (4.2.2.2)"))
o:value("4.2.2.3:53", translate("Level 3 Public DNS (4.2.2.3)"))
o:value("4.2.2.4:53", translate("Level 3 Public DNS (4.2.2.4)"))
o:value("1.1.1.1:53", translate("Cloudflare DNS (1.1.1.1)"))
o:value("114.114.114.114:53", translate("Oversea Mode DNS-1 (114.114.114.114)"))
o:value("114.114.115.115:53", translate("Oversea Mode DNS-2 (114.114.115.115)"))
o:depends("pdnsd_enable", "1")
o:depends("pdnsd_enable", "2")
o:depends("pdnsd_enable", "3")
o:depends("pdnsd_enable", "4")
o:depends("pdnsd_enable", "6")
o.default = "8.8.4.4:53"


-- [[ SOCKS5 Proxy ]]--
s = m:section(TypedSection, "socks5_proxy", translate("SOCKS5 Proxy"))
s.anonymous = true

o = s:option(ListValue, "server", translate("Server"))
o:value("nil", translate("Disable"))
for k, v in pairs(server_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.default = 1080
o.rmempty = false




o = s:option(Flag, "bt", translate("Kill BT"))
o.default = 0
o.rmempty = false
o.description = translate("Prohibit downloading tool ports through proxy")

o = s:option(Value, "bt_port", translate("BT Port"))
o.default = "1236:65535"
o.rmempty = true
o:depends("bt", "1")

-- [[ udp2raw ]]--
if nixio.fs.access("/usr/bin/udp2raw") then

s = m:section(TypedSection, "udp2raw", translate("udp2raw tunnel"))
s.anonymous = true

o = s:option(Flag, "udp2raw_enable", translate("Enable udp2raw"))
o.default = 0
o.rmempty = false

o = s:option(Value, "server", translate("Server Address"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "key", translate("Password"))
o.password = true
o.rmempty = false

o = s:option(ListValue, "raw_mode", translate("Raw Mode"))
for _, v in ipairs(raw_mode) do o:value(v) end
o.default = "faketcp"
o.rmempty = false

o = s:option(ListValue, "seq_mode", translate("Seq Mode"))
for _, v in ipairs(seq_mode) do o:value(v) end
o.default = "3"
o.rmempty = false

o = s:option(ListValue, "cipher_mode", translate("Cipher Mode"))
for _, v in ipairs(cipher_mode) do o:value(v) end
o.default = "xor"
o.rmempty = false

o = s:option(ListValue, "auth_mode", translate("Auth Mode"))
for _, v in ipairs(auth_mode) do o:value(v) end
o.default = "simple"
o.rmempty = false

end

-- [[ udpspeeder ]]--
if nixio.fs.access("/usr/bin/udpspeeder") then

s = m:section(TypedSection, "udpspeeder", translate("UDPspeeder"))
s.anonymous = true

o = s:option(Flag, "udpspeeder_enable", translate("Enable UDPspeeder"))
o.default = 0
o.rmempty = false

o = s:option(Value, "server", translate("Server Address"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "key", translate("Password"))
o.password = true
o.rmempty = false

o = s:option(ListValue, "speeder_mode", translate("Speeder Mode"))
for _, v in ipairs(speeder_mode) do o:value(v) end
o.default = "0"
o.rmempty = false

o = s:option(Value, "fec", translate("Fec"))
o.default = "20:10"
o.rmempty = false

o = s:option(Value, "mtu", translate("Mtu"))
o.datatype = "uinteger"
o.default = 1250
o.rmempty = false

o = s:option(Value, "queue_len", translate("Queue Len"))
o.datatype = "uinteger"
o.default = 200
o.rmempty = false

o = s:option(Value, "timeout", translate("Fec Timeout"))
o.datatype = "uinteger"
o.default = 8
o.rmempty = false

end



return m
