const fs = require('fs').promises;
const path = require('path');
const mime = require('mime-types');
const { spawn } = require('child_process');

const runCliCommand = async ({ cmd, args }) => {
	return new Promise(resolve => {
		const process = spawn(cmd, args);
    
		process.stdout.on('data', data => console.log(`${data}`));
		process.stderr.on('data', data => console.error(`${data}`));

		process.on('exit', resolve);
	});
}

const uploadFile = async ({ filePath, s3, bucketName, bucketPrefix }) => {
  const fileContent = await fs.readFile(filePath);

  const params = {
      Bucket: bucketName,
      Key: `${bucketPrefix}/${filePath.replace('dist/', '')}`, 
      Body: fileContent,
      ContentType: mime.lookup(filePath)
  };

  await s3.upload(params).promise();
  console.log(`File uploaded successfully to ${filePath.replace('dist', `${bucketName}/${bucketPrefix}`)}`);
}

const uploadDir = async ({ dirPath, s3, bucketName, bucketPrefix }) => {
  const files = await fs.readdir(dirPath);
  
  for (const file of files) {
    const filePath = path.join(dirPath, file);
    const stats = await fs.stat(filePath);
    
    if (stats.isFile()) {
      await uploadFile({ 
        filePath, 
        s3, 
        bucketName, 
        bucketPrefix 
      });
    } else if (stats.isDirectory()){
      await uploadDir({ 
        dirPath: filePath, 
        s3, bucketName, 
        bucketPrefix, 
      });
    }
  } 
}

const clearDir = async ({ s3, bucketName, bucketPrefix }) => {
  var params = {
    Bucket: bucketName,
    Prefix: bucketPrefix
  };

  try {
    const listedObjects = await s3.listObjectsV2(params).promise();

    if (listedObjects.Contents.length === 0) return;

    params = {Bucket: bucketName};
    params.Delete = { Objects: [] };

    listedObjects.Contents.forEach(({ Key }) => {
      params.Delete.Objects.push({ Key });
    });

    params.Delete.Objects.push({ Key: `${bucketPrefix}/` });

    await s3.deleteObjects(params).promise();

    if (listedObjects.IsTruncated) await clearDir(bucketName, bucketPrefix);
  } catch (e) {
    console.log(e);
  }
};

module.exports = ({
  serviceName: 'Main Landing UI',

  terraformBackendConfiguration: {
    serviceName: 'www-ui',
    bucket: 'tf-state-backend-imokhonko',
    region: 'us-east-1'
  },

  awsConfiguration: {
    region: 'us-east-1',
    profile: 'default',
  },
  
  config: {
    hostedZone: 'imokhonko.com',
    subdomain: 'www',
  },

  deploy: async ({ feature, infrastructure, AWS }) => {
    const cloudfront = new AWS.CloudFront({ apiVersion: '2019-03-26' });  
    const s3 = new AWS.S3({ apiVersion: '2006-03-01' });
    
    await Promise.all([
      // instal dependencies
      runCliCommand({
        cmd: 'pnpm',
        args: ['i']
      }),

      // build project
      runCliCommand({
        cmd: 'pnpm',
        args: ['run', 'build']
      }),

       // clear old files in bucket for this feature
      clearDir({
        s3,
        bucketName: infrastructure.globalResources.s3.bucketName, 
        bucketPrefix: feature,
      })
    ]);

    await uploadDir({
      dirPath: 'dist', 
      bucketName: infrastructure.globalResources.s3.bucketName, 
      bucketPrefix: feature,
      s3
    });

    const distribtuionId = feature === 'master'
      ? infrastructure.globalResources.cloudfront.masterFeatureDistributionId
      : infrastructure.globalResources.cloudfront.featuresDistributionId

    await cloudfront.createInvalidation({
      DistributionId: distribtuionId,
      InvalidationBatch: {
          CallerReference: '' + (new Date().getTime()), 
          Paths: {
              Quantity: 1,
              Items: feature === 'master' ? [`/*`] : [`/${feature}/*`]
        }
      }
    }).promise();
  },
});