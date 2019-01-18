# Powering off all hosts via IPMI
ipmitool -I lanplus -H 10.10.205.5 -U admin -P "admin" power soft

# vSphere Nodes
ipmitool -I lanplus -H 10.10.205.10 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.15 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.20 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.25 -U ADMIN -P "ADMIN" power  soft
ipmitool -I lanplus -H 10.10.205.30 -U ADMIN -P "ADMIN" power  soft

# AHV Nodes
ipmitool -I lanplus -H 10.10.205.50 -U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.55 -U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.60 -U ADMIN -P "ADMIN" power soft

# Rubrik Nodes
ipmitool -I lanplus -H 10.10.205.70-U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.71 -U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.72 -U ADMIN -P "ADMIN" power soft
ipmitool -I lanplus -H 10.10.205.73-U ADMIN -P "ADMIN" power soft