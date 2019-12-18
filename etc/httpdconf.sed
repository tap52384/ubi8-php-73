196s/\"\ combined/\ %{X-Forwarded-For}i "\ combined/
197s/\"\ common/\ %{X-Forwarded-For}i "\ common/
$a \
<IfModule remoteip_module> \
    RemoteIPHeader X-Forwarded-For \
    # SNATS for F5MWS \
    RemoteIPInternalProxy 172.22.158.129 \
    RemoteIPInternalProxy 172.22.158.130 \
    RemoteIPInternalProxy 172.22.158.131 \
    RemoteIPInternalProxy 172.22.158.132 \
    RemoteIPInternalProxy 172.22.158.133 \
    RemoteIPInternalProxy 172.22.158.134 \
    RemoteIPInternalProxy 172.22.158.160 \
    RemoteIPInternalProxy 172.22.158.161 \
    RemoteIPInternalProxy 172.22.158.162 \
    RemoteIPInternalProxy 172.27.153.6 \
    RemoteIPInternalProxy 172.27.153.5 \
</IfModule>
