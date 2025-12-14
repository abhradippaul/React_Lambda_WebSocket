const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const {
  ApiGatewayManagementApiClient,
  PostToConnectionCommand,
} = require("@aws-sdk/client-apigatewaymanagementapi");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const sendToMany = (items, message, senderConnectionId, callbackAPI) => {
  return items.map(async ({ connectionId }) => {
    if (connectionId !== senderConnectionId) {
      try {
        await callbackAPI.send(
          new PostToConnectionCommand({
            ConnectionId: connectionId,
            Data: message,
          })
        );
      } catch (e) {
        console.log(e);
      }
    }
  });
};

const sendToOne = (items, message, senderConnectionId, callbackAPI) => {};

exports.handler = async function (event) {
  const ddbcommand = new ScanCommand({
    TableName: process.env.TABLE_NAME,
  });

  let connections;
  try {
    connections = await docClient.send(ddbcommand);
  } catch (err) {
    console.log(err);
    return {
      statusCode: 500,
    };
  }

  const callbackAPI = new ApiGatewayManagementApiClient({
    apiVersion: "2018-11-29",
    endpoint:
      "https://" +
      event.requestContext.domainName +
      "/" +
      event.requestContext.stage,
  });

  const message = JSON.parse(event.body).message;
  let sendMessages;

  sendMessages = sendToMany(
    connections.Items,
    message,
    event.requestContext.connectionId,
    callbackAPI
  );

  // const sendMessages = connections.Items.map(async ({ connectionId }) => {
  //   if (connectionId !== event.requestContext.connectionId) {
  //     try {
  //       await callbackAPI.send(
  //         new PostToConnectionCommand({
  //           ConnectionId: connectionId,
  //           Data: message,
  //         })
  //       );
  //     } catch (e) {
  //       console.log(e);
  //     }
  //   }
  // });

  try {
    await Promise.all(sendMessages);
  } catch (e) {
    console.log(e);
    return {
      statusCode: 500,
    };
  }

  return { statusCode: 200 };
};
