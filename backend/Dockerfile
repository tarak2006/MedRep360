# Use official lightweight Node.js image
FROM node:20-alpine

# Set working directory in container
WORKDIR /usr/src/app

# Copy package manifests
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy application source code
COPY . .

# Expose port
EXPOSE 5000

# Run the app
CMD [ "node", "src/server.js" ]
