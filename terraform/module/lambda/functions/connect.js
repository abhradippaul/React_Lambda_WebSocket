const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const {
  ApiGatewayManagementApiClient,
  PostToConnectionCommand,
} = require("@aws-sdk/client-apigatewaymanagementapi");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const sendToMany = (
  items,
  message,
  senderConnectionId,
  callbackAPI,
  newMemberName
) => {
  return items.map(async ({ connectionId, name }) => {
    if (connectionId !== senderConnectionId) {
      try {
        await callbackAPI.send(
          new PostToConnectionCommand({
            ConnectionId: connectionId,
            Data: JSON.stringify({
              members: message,
              type: "connect",
              name: newMemberName,
            }),
          })
        );
      } catch (e) {
        console.log(e);
      }
    }
  });
};

exports.handler = async function (event) {
  const name = event?.queryStringParameters?.name;

  if (!name) return { statusCode: 400 };

  const command = new PutCommand({
    TableName: process.env.TABLE_NAME,
    Item: {
      connectionId: event.requestContext.connectionId,
      name,
    },
  });

  try {
    await docClient.send(command);
  } catch (err) {
    console.log(err);
    return {
      statusCode: 500,
    };
  }

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

  const sendMessages = sendToMany(
    connections.Items,
    `${name} has joined the chat`,
    event.requestContext.connectionId,
    callbackAPI,
    name
  );

  try {
    await Promise.all(sendMessages);
  } catch (e) {
    console.log(e);
    return {
      statusCode: 500,
    };
  }

  return {
    statusCode: 200,
  };
};
