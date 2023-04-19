## Add an AWS transit gateway attachment to a Confluent Cloud network
Follow [Confluent transit gateway doc](https://docs.confluent.io/cloud/current/networking/aws-transit-gateway.html#) 
or [Terraform Instructions](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_transit_gateway_attachment]) 
to set up Transit Gateway connection to Confluent Cloud. 

Note that **exact availability zone alignment** between your AWS Transit Gateway, AWS transit gateway attachments, your VPC, and your Confluent Cloud network.

## Validate connectivity
### Validate Kafka connectivity
From an instance within the VPC (or anywhere the previous step’s DNS is set up), run the following to validate Kafka connectivity through AWS Transit Gateway is working correctly.

1. Set an environment variable with the cluster bootstrap URL

    The Bootstrap URL displayed in Confluent Cloud Console includes the port (9092). The BOOTSTRAP value should include the full hostname, but do not include the port. 

   ```
   # For example: `export BOOTSTRAP=lkc-nkodz-0l6je.us-west-2.aws.confluent.cloud`
   export BOOTSTRAP=$<bootstrap-server-url>
   ```

2. Test connectivity to your cluster by running 
   ```
   openssl s_client -connect $BOOTSTRAP:9092 -servername $BOOTSTRAP -verify_hostname $BOOTSTRAP </dev/null 2>/dev/null | grep -E 'Verify return code|BEGIN CERTIFICATE' | xargs
   ```
   
3. Confirm the connectivity

    Expected output is 
    `-----BEGIN CERTIFICATE----- Verify return code: 0 (ok)`

### Validate connectivity using the [Confluent Cloud CLI](https://docs.confluent.io/confluent-cli/current/overview.html)

1. Sign in to Confluent CLI with your Confluent Cloud credentials.
    ```
    confluent login
    ```
   
2. List the clusters in your organization.
    ```
    confluent kafka cluster list
    ``` 
   
3. Select the cluster with AWS PrivateLink you wish to test.
    ```
    confluent kafka cluster use ...
    ``` 
    For example:

    ```
    confluent kafka cluster use lkc-a1b2c
    ```
   
4. Create a cluster API key to authenticate with the cluster.
    ```
    confluent api-key create --resource ... --description ...
    ```
    For example:

    ```
    confluent api-key create --resource lkc-a1b2c --description "connectivity test"
    ``` 

5. Select the API key you just created.
    ```
    confluent api-key use ... --resource ...
    ```
    For example:

    ```
    confluent api-key use WQDMCIQWLJDGYR5Q --resource lkc-a1b2c
    ``` 

6. Create a test topic.
    ```
    confluent kafka topic create test
    ``` 

7. Start consuming events from the test topic.
    ```
    confluent kafka topic consume test
    ``` 

8. Open another terminal tab or window.
9. Start a producer.
    ```
    confluent kafka topic produce test
    ``` 
10. Type anything into the produce tab and hit Enter; press Ctrl+D or Ctrl+C to stop the producer.
11. The tab running consume will print what was typed in the tab running produce.
12. Clean up the connectivity topic.

You’re done! The cluster is ready for use.