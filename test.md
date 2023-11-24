# Confluent clusterlinking

## Why clusterlinking ?
For the migration to Confluent cloud, it is necessary to synchronize the data of the topics between the Kafka HDInsight cluster and Confluent.
The following condition must be met for a successful cluster link

- Kakfka version 2.4 is running on HDInsight
- SSL and SASL_SSL must be configured
- confluent CLI installed with access to the confluent cluster
- Brokers must be reached from confluent cloud ip addresses 20.73.36.185 - 35.196.203.65.  They are whitelisted in de Azure firewall.

## DNAT rules Azure firewall
Each broker has a unique external IP address configured on the Azure firewall. 

Sandbox example DNAT rules

| Rule Collection | Priority Rule collectionname | Rule name | Source    | Port | Protocol | Destination | Translated Address or FQDN |  Translated Port | Action |
|-----------------|------------------------------|-----------|-----------|------|----------|-------------|----------------------------|------------------|--------|
| 200             | kafka                        | wn0-kafka | Confluent | 9094 | TCP      | 20.76.230.43| 10.18.10.16                | 9094             | Dnat   |
| 200             | kafka                        | wn1-kafka | Confluent | 9094 | TCP      | 20.32.249.25| 10.18.10.17                | 9094             | Dnat   |
| 200             | kafka                        | wn2-kafka | Confluent | 9094 | TCP      | 20.13.48.244| 10.18.10.18                | 9094             | Dnat   |
| 200             | kafka                        | wn3-kafka | Confluent | 9094 | TCP      | 20.23.65.106| 10.18.10.15                | 9094             | Dnat   |

    Note The source ip group Confluent should contains whitelisted ip adresses

## Confluent CLI

Login 
```sh
confluent login --no-browser --save
```

Lookup for the environment
```sh
confluent environment list
  Current |     ID     |  Name
----------|------------|----------
          | env-38zq00 | dev
          | env-dg83mz | test
          | env-yovkjj | sandbox
          | t33182     | default
```

```sh
confluent environment use env-yovkjj
Using environment "env-yovkjj"
```

List the cluster
```sh
 confluent kafka cluster list
  |Current |     ID     |      Name       |   Type    | Provider |   Region   | Availability | Status |
  |--------|------------| ----------------|-----------|----------|------------|--------------|--------|
  |        | lkc-d9oo0o | sandbox-cluster | DEDICATED | azure    | westeurope | single-zone  | UP     |
```

Get the certificates from the java keystore on a broker in the HDInsight cluster

    openssl pkcs12 -in kafka.server.keystore.jks -node -out keystore.pem
The following error message can be avoided by adding the correct algorithm to the private key

    Error: REST request failed: Unable to validate cluster link due to error: Unable to create client using provided properties when validating the cluster link: Invalid PEM keystore configs, root cause: java.security.NoSuchAlgorithmException: PBES2 SecretKeyFactory not available
Create a password for the private key

    openssl pkcs8 -in private.key -topk8 -out private.encrypted.key -v1 PBE-SHA1-3DES 

Create a config.properties:

If your PEM format has newlines or \n, replace them with a single space (” “). Here’s an example configuration. The config.properties file should contains:
```sh
security.protocol=SSL
ssl.truststore.type=PEM
ssl.keystore.type=PEM
ssl.keystore.certificate.chain=----BEGIN CERTIFICATE----- MIIEujCCAqICFCyxuoa8oIqckVjgq347fHjMlh/jMA0GCSqGSIb3DQEBCwUAMIG9 MQswCQYDVQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNo dDEMMAoGA1UECgwDREhMMQ4wDAYDVQQLDAVJbmZyYTFGMEQGA1UEAww9aG4wLWth ZmthLjJhajVwd2VrZm4yZXZlYmUxZXhnYXZjcmZmLmF4LmludGVybmFsLmNsb3Vk YXBwLm5ldDEkMCIGCSqGSIb3DQEJARYVcm9uYWxkLnNjaG91d0BkaGwuY29tMB4X  -----END CERTIFICATE-----
ssl.keystore.key=-----BEGIN ENCRYPTED PRIVATE KEY----- MIIE6jAcBgoqhkiG9w0BDAEDMA4ECCuKXaPqyrInAgIIAASCBMg63zo/0ctjGEa1 sQJWgdv7WMOWKVP2qANZ+vH4WHk0fibNEB+YHSOF03SlThMXtvJmzZMbrnP/hO6K LKXRtHqD4cbFEsEHjKIhblMi6uF2zQCIWwzXH+glkx0LQAKbZBKJ8sUKVuvxdHGo = -----END ENCRYPTED PRIVATE KEY-----
ssl.key.password=secret
ssl.truststore.certificates=-----BEGIN CERTIFICATE----- MIIGXTCCBEWgAwIBAgIUcYkOKTLkOX+Y4FOG1iJussmYq7swDQYJKoZIhvcNAQEL BQAwgb0xCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdV dHJlY2h0MQwwCgYDVQQKDANESEwxDjAMBgNVBAsMBUluZnJhMUYwRAYDVQQDDD1o bjAta2Fma2EuMmFqNXB3ZWtmbjJldmViZTFleGdhdmNyZmYuYXguaW50ZXJuYWwu = -----END CERTIFICATE-----
```


Create a cluster link with SSL
```sh
 confluent kafka link create rschouw-link-ssl-encrypted \
 --source-bootstrap-server wn0-kafka.sdbx.dhlparcel.io:9093 \
 --destination-cluster lkc-d9oo0o \
 --cluster lkc-d9oo0o  \
 --config-file config.properties \
 --dry-run \
 --unsafe-trace
```
The option --dry-run is for testing

The option --unsafe-trace is for debugging

Check of the cluster link is created

```sh
confluent kafka link describe rschouw-link-ssl-encrypted
+---------------------+----------------------------+
| Name                | rschouw-link-ssl-encrypted |
| Source Cluster      | p0QcVc8wSM23t6_JxnZyHA     |
| Destination Cluster |                            |
| Remote Cluster      | p0QcVc8wSM23t6_JxnZyHA     |
| State               | ACTIVE                     |
+---------------------+----------------------------+
```

By now the clusterlinking should work when the first mirror topic is created

    confluent kafka mirror create dhl-ssl --link rschouw-link-ssl-encrypted

Produce data to the topic dhl-ssl in the HDInsight cluster. It should also be available instantly in the confluent cluster.

Create a cluster link with SASL_SSL
```sh
 confluent kafka link create rschouw-link-sasl-encrypted \
 --source-bootstrap-server wn0-kafka.sdbx.dhlparcel.io:9094 \
 --destination-cluster lkc-d9oo0o \
 --cluster lkc-d9oo0o  \
 --config-file config.sasl.properties \
 --dry-run \
 --unsafe-trace
```
Where the config.sasl.properties should contains.

If your PEM format has newlines or \n, replace them with a single space (” “). Here’s an example configuration. The config.properties file should contains:
```sh
security.protocol=SASL_SSL
ssl.truststore.type=PEM
ssl.keystore.type=PEM
ssl.keystore.certificate.chain=----BEGIN CERTIFICATE----- MIIEujCCAqICFCyxuoa8oIqckVjgq347fHjMlh/jMA0GCSqGSIb3DQEBCwUAMIG9 MQswCQYDVQQGEwJOTDEQMA4GA1UECAwHVXRyZWNodDEQMA4GA1UEBwwHVXRyZWNo dDEMMAoGA1UECgwDREhMMQ4wDAYDVQQLDAVJbmZyYTFGMEQGA1UEAww9aG4wLWth ZmthLjJhajVwd2VrZm4yZXZlYmUxZXhnYXZjcmZmLmF4LmludGVybmFsLmNsb3Vk YXBwLm5ldDEkMCIGCSqGSIb3DQEJARYVcm9uYWxkLnNjaG91d0BkaGwuY29tMB4X  -----END CERTIFICATE-----
ssl.keystore.key=-----BEGIN ENCRYPTED PRIVATE KEY----- MIIE6jAcBgoqhkiG9w0BDAEDMA4ECCuKXaPqyrInAgIIAASCBMg63zo/0ctjGEa1 sQJWgdv7WMOWKVP2qANZ+vH4WHk0fibNEB+YHSOF03SlThMXtvJmzZMbrnP/hO6K LKXRtHqD4cbFEsEHjKIhblMi6uF2zQCIWwzXH+glkx0LQAKbZBKJ8sUKVuvxdHGo = -----END ENCRYPTED PRIVATE KEY-----
ssl.key.password=secret
ssl.truststore.certificates=-----BEGIN CERTIFICATE----- MIIGXTCCBEWgAwIBAgIUcYkOKTLkOX+Y4FOG1iJussmYq7swDQYJKoZIhvcNAQEL BQAwgb0xCzAJBgNVBAYTAk5MMRAwDgYDVQQIDAdVdHJlY2h0MRAwDgYDVQQHDAdV dHJlY2h0MQwwCgYDVQQKDANESEwxDjAMBgNVBAsMBUluZnJhMUYwRAYDVQQDDD1o bjAta2Fma2EuMmFqNXB3ZWtmbjJldmViZTFleGdhdmNyZmYuYXguaW50ZXJuYWwu = -----END CERTIFICATE-----

sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="user" password="secret";
sasl.mechanism=SCRAM-SHA-512
```






