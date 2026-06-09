This folder contains style entries (as json), sorted by type and sex. A style is an outfit, and editing a style json changes which meshes are used on it, among other things.
When MeshModEnabler loads, it will load all the styles found in the 'reframework\MeshModEnabler\database' folder of your game directory and apply them to the game. You can include one of these json files with your mod to change articles, underwear, hidden parts etc of the style it uses. Use the json files in the 'reference' folder to see which style entries are which.


NOTE: Currently it is not possible to write very large UInt64 values in REFramework, so this means you may not be able to change the enums for hiding mesh parts ("PartsEnable" fields) depending on how large the enum numbers are for what you're trying to set. Enum values can be written numbers or as strings (such as "ALL" or "None"), both will work.


You can download EMV Engine + Console from the link below to preview these same style entries live in the game. Simply type "sdk.get_managed_singleton('app.CharacterEditManager')" (without quotes) into the console and navigate to TopsDB, PantsDB, MantleDB or HelmDB, and find your item in the database. There you can edit the items and see what the changes are with instant results from the inventory menu, then translate those results back to a json file here.

https://github.com/alphazolam/EMV-Engine