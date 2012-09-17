#!/bin/bash

# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}



# Checks that the IP address exists in DHCPD Leases file
function check_leases()
{
    local  ip=$1
    result=$(grep -n $1 /var/lib/dhcpd/dhcpd.leases)
    if [[ ${#result[@]} -gt 0 ]]; then
    	return 1
    else
    	return 0
    fi
}

function get_mac_address()
{
    
    export address=$1
    mac_address=$(awk 'BEGIN{
                                    RS="}"
                                    FS="\n"
                                 }
                        /lease/{
                                    for(i=1;i<=NF;i++){
                                        gsub(";","",$i)
                                        if ($i ~ /lease/) {
                                            m=split($i, IP," ")
                                            ip=IP[2]
                                        }
                                        if( $i ~ /hardware/ ){
                                            m=split($i, hw," ")
                                            ether=hw[3]
                                        }

                                    }
                                    if (ip == ENVIRON["address"]){
                                        print ether 
                                        
                                    }
                        }' /var/lib/dhcpd/dhcpd.leases | uniq)
    #clean up
    export address=""
    echo $mac_address

}


# We store arguments from bash command line in special array
args=("$@")
ip=${args[0]}
if [[ ${#args[@]} != 1 ]]; then
	echo "Invalid input! <ip>"
	exit
fi
valid_ip $ip
if [[ $? -ne 0 ]]; then
	echo "Invalid IP"
	exit 
fi
#We know we have a valid IP address and it is the only parameter
check_leases $ip 
if [[ $? -ne 0 ]]; then
	get_mac_address $ip
else
	echo "IP not Found in Lease"
fi
















