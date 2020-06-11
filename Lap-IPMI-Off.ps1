# Powering off all hosts via IPMI
ipmitool -I lanplus -H 10.10.205.5 -U admin -P "admin" power soft

# vSphere Nodes
ipmitool -I lanplus -H 10.10.205.100 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.115 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.15 -U ADMIN -P "ADMIN" power  soft
#ipmitool -I lanplus -H 10.10.205.20 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.25 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.30 -U ADMIN -P "ADMIN" power  soft

# AHV Nodes
ipmitool -I lanplus -H 10.10.205.50 -U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.55 -U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.60 -U ADMIN -P "ADMIN" power soft

