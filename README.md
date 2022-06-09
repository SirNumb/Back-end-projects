# Back-end-projects

## 1 : A* Pathfinder Algorithm implementation on ROBLOX

  A node based pathfinder algorithm translated from c-sharp for luau with very fast Responses
  Uses a 2D grid and can find paths utterly fast!
  
### Speed compared between other algorithms (seeded noise with possible ending)
  - Roblox default pathfinder : ~76ms
  - Custom open source a* algorithm : ~5ms
  - My A* implementation : ~2.5ms

Perlin noise example:
####  - Custom open source a* algorithm :

![RobloxStudioBeta_XEUHD50zk7](https://user-images.githubusercontent.com/69503016/172947879-702a6c8d-c6bc-4fb5-a962-9f4ad83cd9e1.png)
####  - My A* implementation :

![RobloxStudioBeta_dGAB4lfm6c](https://user-images.githubusercontent.com/69503016/172948020-4b021b2b-1a7d-42ac-b1e4-e2c4be7496eb.png)

## 2 : Backend database protocol for external databases

  A custom database system that works with many REST API databases without modifying the structure of the code much
  Currently it have been tested with CouchDB and Redis Cache databases
  It supports bulk/pipeline requests with multiple keys ( 1 HTTP request for 100 keys! )
  
  ### Database settings:
```Lua
	--[[
		//Database_Settings;
	--]]
	database_ip = "IP" , -- current database IP address
	database_port = "PORT" , -- current database connection port
	database_user = "USER" , -- to establish a connection a username is required
	database_pass = "PASSWORD" , -- to establish a connection a password is required
	database_accountDB = "DATABASE1" , -- database name that stores account settings (db names must start with one underscore{_} in order to work)
	database_silent_print = true , -- Used to save data as the connection is instantly shut off after
	POST_or_GET_attempts = 3 , -- number of attempts before dropping the request
	POST_or_GET_attempts_Cooldown = 10 , -- seconds til the server will attempt the search for the data again
	database_timeout = 30 , -- amount of seconds til the database request will return nil
	save_only_changes = true , -- TODO_Deprecated !Recommended if the database will only send modified data back at the Realtime Database (Can prevent useless overwrites or Unique keys being modified)
	server_shutdown_data_saving = true , -- whenever you want to save the data if the server is currently closing (BindToClose)
	server_shutdown_bundle_data_saving = true , -- {WARNING! server_shutdown_data_saving must be true }sends one HTTP request with all the data instead of more
	server_shutdown_bundle_max = 700 , -- max amount of keys that can be in one saving bundle , similar with autosave_bulk_max!
	server_shutdown_bundle_cooldown = 1 , -- cooldown between bundles if one reaches the maximum limit
	autosaves = true , -- if the data will be autosaved every N second this can prevent losing data when the server crashes
	autosaves_cooldown = 60 , -- seconds til the server will autosave the data, smaller can ensure that the data is safer
	autosave_bulks = true , -- keys will be saved in http bulks instead of individually sending one update request per key (recommended for giant servers)
	autosave_bulk_max = 700 , -- max amount of keys that can be in one saving bulk , similar with server_shutdown_bundle_max!
	autosave_bulk_cooldown = 2 , -- cooldown between bulks if one reaches the maximum limit
	http_soft_limit = 350 , -- how many http requests will trigger the soft limit system (see down for more info)
	soft_delay = 2 , -- amount of seconds each request will be delayed during the soft limit
	soft_delay_leaving_queues = false , -- the leaving data will skip the queue and be sent to the database instantly, this can prevent item dublications!
	http_hard_limit = 400 , -- how many http request can the database send per minute, if the limit is passed the key will be put on hold
	join_data_request_delay = 0 , -- amount of seconds the server will wait before getting the data, used to prevent overwriting data especially because bundled data can take longer to upload
```

  it should support any REST NOSQL database systems using json data structures (for Redis, string is supported as well as long as it stores a JSON table inside)
  the code is lightweight and documented as well
  
## 3 : Pizzeria Tycoon Framework
  
  A Pizzeria game framework inspired by restaurant tycoon where you build your own restaurant and server customers in this case nice pizzas :)
  
### Features working:
###   - Ordering:
   (Customers will come to the booth and they will ask for a table, after interacting they will start moving to the given table)
   
  joe asking for a table:
  
![RobloxStudioBeta_2zy6ca9oO5](https://user-images.githubusercontent.com/69503016/172950169-43490b10-d377-4c4a-b370-bc7cbbe39bbb.png)

  joe in a parallel universe where he isnt bald but got a moustache looking at the menu:  
  
![RobloxStudioBeta_HPDr2uPAWX](https://user-images.githubusercontent.com/69503016/172950256-52caa4ef-7e18-41a0-9699-31b2921a8141.png)

###   - Building:
  (Build the restaurant the way you want aditionally it does a lot of back end processing such as
    - making sure the assets do not collide with each other
    - checking the structure of tables "if each chair is facing the table or if the chair got a table next to it"
    - checking if the customers can reach the certain item "if a chair cannot be reached it will be considered a solid prop and it will no longer be functional"
  )
  
  https://user-images.githubusercontent.com/69503016/172952027-28521bf7-7933-44d0-bff7-38fb8fdd0088.mp4

The project is very modular and no open source modules or anything had been used, models/textures/bakes, animations and GUI are also made by me but they are not permanent.

###   - Other pics:

  noobs trying to order:  

  ![RobloxStudioBeta_FR45HiasCQ](https://user-images.githubusercontent.com/69503016/172952396-73b93554-7d7a-4a88-9e26-519cd47e5dc2.png)
  
  people receiving their deserved pizza:
 
  ![RobloxStudioBeta_7IMI7hNva7](https://user-images.githubusercontent.com/69503016/172952572-c67c7b09-b8df-44c1-a781-6c7663ecc6b7.png)
  

## 4 : Other Systems:

### Pet Simulator Framework:
   a little project trying to make a simulator such as pet simulator but with little humans instead :D
   
#### Chest opening system:
https://user-images.githubusercontent.com/69503016/172953280-75333f86-cca8-4a3e-af54-52bdb05a06f2.mp4

#### Pet System:
https://user-images.githubusercontent.com/69503016/172953580-efa4db99-0c18-42bc-8992-3f9c2e700caa.mp4

#### Combat System:
https://user-images.githubusercontent.com/69503016/172953816-ce113d37-084e-4d42-aefb-73414fd8fd1e.mp4

### VideoFrame & custom video format:
   I took a break from the development of my projects and started working on a custom video format which can be easily translated in many engines **Including** roblox
   It uses python to process the mp4 videos and turn them into a custom format.
   About the video format:
    i called them .numb files because why not but in a nutshell it is a lossless, 5bit, 30k colors video format that is trying to be performant but also easy to implement without the requirement of any decoders as the pixel values are directly stored and it supports commands such as skip pixel or sequence colors ( helpful when the next frame is almost the same as the one before so the player will only change the pixels that changed in the next frame)

#### the dictionary table:
```Python
    key_table = {
    0  : "0",
    1  : "1",
    2  : "2",
    3  : "3",
    4  : "4",
    5  : "5",
    6  : "6",
    7  : "7",
    8  : "8",
    9  : "9",
    10 : "A",
    11 : "B",
    12 : "C",
    13 : "D",
    14 : "E",
    15 : "F",
    16 : "G",
    17 : "H",
    18 : "I",
    19 : "J",
    20 : "K",
    21 : "L",
    22 : "M",
    23 : "N",
    24 : "O",
    25 : "P",
    26 : "Q",
    27 : "R",
    28 : "S",
    29 : "T",
    30 : "x", ##skip frame
    31 : "*", ##instruction sequence modification
}

binary_table = {
    "0" : b"00000",
    "1" : b"00001",
    "2" : b"00010",
    "3" : b"00011",
    "4" : b"00100",
    "5" : b"00101",
    "6" : b"00110",
    "7" : b"00111",
    "8" : b"01000",
    "9" : b"01001",
    "A" : b"10000",
    "B" : b"01010",
    "C" : b"01011",
    "D" : b"01100",
    "E" : b"01101",
    "F" : b"01110",
    "G" : b"01111",
    "H" : b"10001",
    "I" : b"10010",
    "J" : b"10011",
    "K" : b"10100",
    "L" : b"10101",
    "M" : b"10110",
    "N" : b"10111",
    "O" : b"11000",
    "P" : b"11001",
    "Q" : b"11010",
    "R" : b"11011",
    "S" : b"11100",
    "T" : b"11101",
    "x" : b"11110", ##skip frame
    "*" : b"11111", ##instruction sequence modification
}
```

### Examples :
https://user-images.githubusercontent.com/69503016/172955075-5f39a327-3577-4da8-9fc4-d08ce4499400.mp4

https://user-images.githubusercontent.com/69503016/172955171-0aea4501-4671-4391-a304-5f20dfd8cadd.mp4

https://user-images.githubusercontent.com/69503016/172955282-4ca9ffb2-7bef-4206-88fa-8814da27a2b7.mp4








