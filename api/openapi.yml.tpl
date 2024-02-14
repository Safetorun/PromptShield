openapi: '3.0.0'
info:
  version: '1.0.0'
  title: 'PromptDefender - PII and Prompt Injection Verification Service'
  description: "PromptDefender's API provides a mechanism to strip PII and check for prompt injection, ensuring safe text processing."
  contact:
    name: 'Support'
    email: 'admin@safetorun.com'

servers:
  - url: 'https://prompt.safetorun.com'
    description: 'Production server'

paths:
  /wall:
    post:
      x-amazon-apigateway-integration:
        uri: ${lambda_moat_arn}
        passthroughBehavior: "when_no_match"
        httpMethod: "POST"
        type: "aws_proxy"
      summary: 'Verify and Analyze Prompt'
      description: 'This endpoint accepts a text prompt and provides a first layer of defense against prompt injection'
      operationId: 'wallPrompt'
      security:
        - ApiKeyAuth: [ ]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/WallRequest'
      responses:
        '200':
          description: 'Successful operation.'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/WallResponse'
        '400':
          description: 'Bad request. The prompt field is missing or invalid.'
        '500':
          description: 'Internal server error.'
  /keep:
    post:
      x-amazon-apigateway-integration:
        uri: ${lambda_keep_arn}
        passthroughBehavior: "when_no_match"
        httpMethod: "POST"
        type: "aws_proxy"
      summary: 'Improve your prompts security with instruction defense'
      description: 'This endpoint accepts a text prompt, strips PII, and checks it for prompt injection, returning an injection score.'
      operationId: 'buildKeep'
      security:
        - ApiKeyAuth: [ ]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/KeepRequest'
      responses:
        '200':
          description: 'Successful operation.'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/KeepResponse'
        '400':
          description: 'Bad request. The prompt field is missing or invalid.'
        '500':
          description: 'Internal server error.'
  /moat:
    post:
      x-amazon-apigateway-integration:
        uri: ${lambda_moat_arn}
        passthroughBehavior: "when_no_match"
        httpMethod: "POST"
        type: "aws_proxy"
      summary: 'This endpoint accepts a text prompt, strips PII, and checks it for prompt injection, returning an injection score.'
      description: 'Moat is an API that is called before every request to your API. It checks the request for PII and prompt injection, and returns a score indicating the likelihood of injection.'
      operationId: 'buildShield'
      security:
        - ApiKeyAuth: [ ]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/MoatRequest'
      responses:
        '200':
          description: 'Successful operation.'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/MoatResponse'
        '400':
          description: 'Bad request. The prompt field is missing or invalid.'
        '500':
          description: 'Internal server error.'
  /user:
    get:
      summary: 'List Suspicious Users'
      description: 'This endpoint returns a list of suspicious users.'
      operationId: 'listUsers'
      responses:
        '200':
          description: 'Successful operation.'
          content:
            application/json:
              schema:
                type: 'array'
                items:
                  $ref: '#/components/schemas/User'
        '500':
          description: 'Internal server error.'
    post:
      summary: 'Add Suspicious User'
      description: 'This endpoint adds a user to the list of suspicious users.'
      operationId: 'addUser'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/User'
      responses:
        '201':
          description: 'User successfully added.'
        '400':
          description: 'Bad request. The user data is missing or invalid.'
        '500':
          description: 'Internal server error.'
    delete:
      summary: 'Remove Suspicious User'
      description: 'This endpoint removes a user from the list of suspicious users.'
      operationId: 'removeUser'
      parameters:
        - name: 'userId'
          in: 'query'
          required: true
          schema:
            type: 'string'
      responses:
        '200':
          description: 'User successfully removed.'
        '400':
          description: 'Bad request. The userId is missing or invalid.'
        '500':
          description: 'Internal server error.'

components:
  securitySchemes:
    ApiKeyAuth:
      type: 'apiKey'
      in: 'header'
      name: 'x-api-key'
      description: 'API key required for AWS API Gateway'
  schemas:
    User:
      type: 'object'
      properties:
        userId:
          type: 'string'
          description: 'The user ID of the suspicious user.'
    KeepRequest:
      type: 'object'
      required:
        - 'prompt'
      properties:
        randomise_xml_tag:
          type: 'boolean'
          description: 'Whether to randomise the XML tag that is used to escape user input in your prompt.'
        prompt:
          type: 'string'
          description: 'The base prompt you want to build a keep for'

    MoatRequest:
      type: 'object'
      required:
        - 'prompt'
        - 'scan_pii'
      properties:
        user_id:
          type: 'string'
          description: 'The user ID of the user who is submitting the prompt. This is used to flag suspicious users'
        session_id:
            type: 'string'
            description: 'The session ID of the user who is submitting the prompt. This is used to flag suspicious sessions'
        prompt:
          type: 'string'
          description: 'The text prompt to be verified.'
        scan_pii:
          type: 'boolean'
          description: 'Whether to scan for PII in the prompt.'
        xml_tag:
          type: 'string'
          description: 'The XML tag that is used to escape user input in your prompt (this may have been generated with keep).'
    WallRequest:
      type: 'object'
      required:
        - 'prompt'
      properties:
        prompt:
          type: 'string'
          description: 'The text prompt to be verified.'

    KeepResponse:
      type: 'object'
      required:
        - 'shielded_prompt'
        - 'xml_tag'
      properties:
        shielded_prompt:
          type: 'string'
          description: 'The shielded prompt.'
        xml_tag:
            type: 'string'
            description: 'The XML tag that is used to escape user input in your prompt.'

    MoatResponse:
      type: 'object'
      properties:
        contains_pii:
          type: 'boolean'
          description: 'Whether the prompt contains PII.'
        potential_jailbreak:
          type: 'boolean'
          description: 'Whether the prompt contains a potential jailbreak.'
        potential_xml_escaping:
          type: 'boolean'
          description: 'Whether the prompt contains potential XML escaping.'
        suspicious_user:
          type: 'boolean'
          description: 'Whether the user is suspicious.'
        suspicious_session:
            type: 'boolean'
            description: 'Whether the session is suspicious.'

    WallResponse:
      type: 'object'
      properties:
        injection_score:
          type: 'number'
          format: 'float'
          description: 'The score indicating the likelihood of prompt injection.'
