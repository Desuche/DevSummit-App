import express from "express";
import { OAuth2Client } from "google-auth-library";
import {
  createAuthUser,
  createEmptyUser,
  createUser,
  getUserById,
  getUserIdByPlatformAndPlatformUserID,
} from "../db";
import { PlatformName } from "../models/authuser";
import { User } from "../models/user";
const jwt = require("jsonwebtoken");
const router = express.Router();

const googleClient = new OAuth2Client();
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;

const generateJWT = (user: User) => {
  const payload = user;

  const secret = process.env.JWT_SECRET;
  const options = {
    expiresIn: "1h",
  };

  return jwt.sign(payload, secret, options);
};

/*
 * If user has not registered, DO NOT auto create user, rather return a 404 for them to register.
 */
router.post("/login/phone", async (req, res) => {
  let phone = req.body.phone;
  let token = req.body.token;

  if (!phone || !token) {
    res.status(400).json({ message: "Phone and token are required" });
    return;
  }

  /*Authenticate token
    * If token is valid, create a new user (if needed) and generate JWT
        phone token is mocked for now as "12345"
    */

  if (token !== "12345") {
    res.status(401).json({ message: "Invalid token" });
    return;
  }

  var userId;

  let existingUser = await getUserIdByPlatformAndPlatformUserID(
    PlatformName.Phone,
    phone
  );
  if (!existingUser) {
    res.status(404).json({ message: "User not found" });
    return;
  } else {
    userId = existingUser;
  }

  let user = await getUserById(userId);
  if (!user) {
    res.status(500).json({ message: "Internal server error" });
    return;
  }

  //Generate JWT
  try {
    let jwt = generateJWT(user);
    res.status(200).json({ jwt });
  } catch (error) {
    console.error("Error generating JWT:", error);
    res.status(500).json({ message: "Internal server error" });
    return;
  }
});

router.post("/checkregistration/phone", async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    res.status(400).json({ message: "Phone is required" });
    return;
  }

  let existingUser = await getUserIdByPlatformAndPlatformUserID(
    PlatformName.Phone,
    phone
  );

  if (!existingUser) {
    res.status(404).json({ message: "User not found" });
    return;
  }

  res.status(200).json({ message: "User is registered" });
});

router.post("/register/phone", async (req, res) => {
  const { name, email, phone } = req.body;

  if (!phone || !name || !email) {
    res.status(400).json({ message: "Phone, name and email are required" });
    return;
  }

   
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    res.status(400).json({ message: "Invalid email format" });
    return;
  }

  let existingUser = await getUserIdByPlatformAndPlatformUserID(
    PlatformName.Phone,
    phone
  );

  if (existingUser) {
    res.status(409).json({ message: "Phone number already exists" });
    return;
  }

  try {
    let userId = await createUser(name, email);
    await createAuthUser(userId, phone, PlatformName.Phone);
  } catch (error) {
    console.error("Error creating user:", error);
    res.status(500).json({ message: "Internal server error" });
    return;
  }

  res.status(200).json({ message: "User created successfully" });

});

router.post("/login/facebook", async (req, res) => {
  let { accessToken } = req.body;
  if (!accessToken) {
    res.status(400).json({ message: "Access token is required" });
    return;
  }

  interface FacebookUser {
    id?: string;
    name?: string;
    email?: string;
  }

  var facebookUser: FacebookUser = { };

  try {
    // Verify the access token with Facebook
    const response = await fetch(
      `https://graph.facebook.com/me?access_token=${accessToken}&fields=id,name,email`
    );
    const data = await response.json();
    if (data.error) {
      res.status(401).json({ message: "Invalid access token" });
      return;
    }

    if (response.ok) {
      facebookUser = { id: data.id, name: data.name, email: data.email };
    }
  } catch (error) {
    console.error("Error verifying access token:", error);
    res.status(500).json({ message: "Internal server error" });
    return;
  }

  if (!facebookUser || !facebookUser?.id || !facebookUser?.name || !facebookUser?.email) { 
    res.status(401).json({ message: "Invalid access token" });
    return;
  }

  let userId;
  let existingUser = await getUserIdByPlatformAndPlatformUserID(
    PlatformName.Facebook,
    facebookUser.id
  );
  if (!existingUser) {
    //Create user
    try {
      userId = await createUser(facebookUser.name, facebookUser.email);
      await createAuthUser(userId, facebookUser.id, PlatformName.Facebook);
    } catch (error) {
      console.error("Error creating user:", error);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
  } else {
    userId = existingUser;
  }

  let user = await getUserById(userId);

  if (!user) {
    res.status(500).json({ message: "Internal server error" });
    return;
  }

  //Generate JWT
  try {
    let jwt = generateJWT(user);
    res.status(200).json({ jwt });
  } catch (error) {
    console.error("Error generating JWT:", error);
    res.status(500).json({ message: "Internal server error" });
    return;
  }
});

router.post("/login/google", async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) {
    res.status(400).json({ message: "Id token is required" });
    return;
  }

  interface GoogleUser {
    id?: string;
    name?: string;
    email?: string;
  }

  var googleUser: GoogleUser = {};

  try {
    // Verify the id token with Google
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    googleUser = { id: payload?.sub, name: payload?.name, email: payload?.email };
  } catch (error) {
    console.error("Error verifying id token:", error);
    res.status(401).json({ message: "Invalid id token" });
    return;
  }

  if (!googleUser || !googleUser?.id || !googleUser?.name || !googleUser?.email) {
    res.status(401).json({ message: "Invalid id token" });
    return;
  }

  let userId;

  let existingUser = await getUserIdByPlatformAndPlatformUserID(
    PlatformName.Google,
    googleUser.id
  );
  if (!existingUser) {
    //Create user
    try {
      userId = await createUser(googleUser.name, googleUser.email);
      await createAuthUser(userId, googleUser.id, PlatformName.Google);
    } catch (error) {
      console.error("Error creating user:", error);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
  } else {
    userId = existingUser;
  }

  let user = await getUserById(userId);
  if (!user) {
    res.status(500).json({ message: "Internal server error" });
    return;
  }

  //Generate JWT
  try {
    let jwt = generateJWT(user);
    res.status(200).json({ jwt });
  } catch (error) {
    console.error("Error generating JWT:", error);
    res.status(500).json({ message: "Internal server error" });
    return;
  }
});

export default router;
