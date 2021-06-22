# aws-lambda-remove-exif
Simple lambda function for removing exif data from image and uploading to s3

This is a lambda function written in python that gets triggered when an image is uploaded to an s3 bucket. When triggered, the function will take the uploaded image, strip it's exif data and uploads the image to a different s3 bucket. 

The main.tf file will use Terraform to deploy the solution. It also creates two users. User A can read/write to bucket A and User B can read from Bucket B.

The packaging of lambda.zip needs to be done maunally. To create lambda.zip follow these steps:

```bash
pip3 install --target ./package exif
cd package
zip -r ../lambda.zip .
cd ..
zip -g lambda.zip lambda_function.py
```
