import { Handler } from '@netlify/functions'

export const handler: Handler = async (event, context) => {
  const secret = process.env.EXAMPLE_SECRET;

  return {
    statusCode: 200,
    body: `my secret value is: ${secret}`
  }
}
