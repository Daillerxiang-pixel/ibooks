import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module.js";
import * as dotenv from "dotenv";

dotenv.config();

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  app.enableCors({
    origin: true,
    credentials: true,
  });
  
  app.setGlobalPrefix("api");
  
  const port = process.env.PORT || 8081;
  await app.listen(port);
  console.log(`iBooks server running at http://localhost:${port}`);
}

bootstrap();