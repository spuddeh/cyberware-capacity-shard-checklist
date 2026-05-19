-- ======================================================================================
-- Mod Name: Cyberware Capacity Shard Checklist
-- Author: Spuddeh
-- Description: Database of Cyberware Capacity Shard locations and Cyberjunkie NPCs.
-- Mod Version: 1.0.0
-- ======================================================================================

local CyberwareCapacityDB = {
    -- ==================================================================================
    -- Category 1: Cyberware Capacity Shards
    -- These Cyberjunkies (and one cache) drop a Cyberware Capacity Shard when looted.
    -- ==================================================================================
    {
        category = "Cyberware Capacity Shards",
        entries = {
            {
                id = "dogtown_stadium_cache",
                name = "Stadium Parking Garage (Cache)",
                fast_travel = "Stadium Parking",
                directions =
                "During the 'Dog Eat Dog' mission, From the top of the parking garage, where you go to leave with Songbiard, turn around and head down the walkway leading away from the door (slightly to the right). When you reach the end, loot just to the right of the pillar, you should see a blue van. The shard will be in a container inside the rear of the van.\nInteract with the trunk to open it and access the container.\n\n---!!!POTENTIALLY MISSABLE!!!---\nIf you miss it during the mission, the prompt to open the trunk will be removed, if you aim at the door handle right, you can access the container through the door.",
                coords = { x = -1298.7089, y = -1930.1709, z = 28.1318, yaw = 35.1215 },
                requirement = "Dog Eat Dog (Main Quest)",
                district = "Dogtown",
                sub_district = "Stadium",
                quest_fact = nil,
                container_id = 1147363412753161741ULL,
                conversation_shard = nil -- Cache, not a Cyberjunkie
            },
            {
                id = "cyberjunkie_wesley_hunt",
                name = "Cyberjunkie - Wesley Hunt",
                fast_travel = "Terra Cognita",
                directions =
                "Facing the fast travel terminal, turn around and head up the stairs into Terra Cognita. As you pass through the gates, turn left and head up the road. Follow the road until you get to a round orange building with an 'Anatomicon' sign. Wesley Hunt will be inside. Take him out and the shard will be on his body.",
                coords = { x = -2242.2029, y = -3092.9231, z = 130.0221, yaw = 112.6099 },
                requirement = "",
                district = "Dogtown",
                sub_district = "Terra Cognita",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_01_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_01_finished", -- Quest fact for Cyberjunkie death
                container_id = 9000933ULL,         -- Character.cbj_ep1_001_cyberjunkie
                conversation_shard = "Wesley Hunt and Michael Bell"
            },
            {
                id = "cyberjunkie_jacob_bernard",
                name = "Cyberjunkie - Jacob Bernard",
                fast_travel = "Longshore Stacks",
                directions =
                "From the fast travel terminal, head north east towards Ronald P.T.Malone and continue down the alley until you get to a basketball court. You will see bodies leading up to the court and Jacob Bernard, will be inside if you met all the requirements. Take him out and the shard will be on his body.",
                coords = { x = -2408.7122, y = -2589.2354, z = 23.1916, yaw = 27.4183 },
                requirement = "Defeat any 4 Cyberjunkies.",
                district = "Dogtown",
                sub_district = "Longshore Stacks",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_03_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_03_finished", -- Quest fact for Cyberjunkie death
                container_id = 9006678ULL,         -- Character.cbj_ep1_003_cyberjunkie
                conversation_shard = "Jacob Bernard and Martha Bernard"
            },
            {
                id = "cyberjunkie_garry_bates",
                name = "Cyberjunkie - Garry Bates",
                fast_travel = "Golden Pacific",
                directions =
                "Facing the fast travel terminal turn right and head up the road between the two buildings (Roar of Eden Club & Pride of Eden Casino). Head past the intersection and continue up the hill. Turn right at the next intersection and continue up the road. You should see the Brave Atlas (a metal wireframe globe) up to your right. Head towards that. Garry Bates will be inside. Take him out and the shard will be on his body.",
                coords = { x = -1945.9369, y = -2701.0588, z = 85.2568, yaw = -14.2032 },
                requirement = "",
                district = "Dogtown",
                sub_district = "Golden Pacific",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_04_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_04_finished", -- Quest fact for Cyberjunkie death
                container_id = 9000966ULL,         -- Character.cbj_ep1_004_cyberjunkie
                conversation_shard = "Garry Bates and Matthew Choi"
            },
            {
                id = "cyberjunkie_jacqueline_peele",
                name = "Cyberjunkie - Jacqueline Peele",
                fast_travel = "Golden Pacific",
                directions =
                "Facing the fast travel terminal, head up the sidewalk until you get to the rubble blocking the way. Turn left, and head down the alley directly ahead. Jacqueline Peele will be inside. Take her out and the shard will be on her body.",
                coords = { x = -1937.5730, y = -2337.9233, z = 39.5025, yaw = 17.1816 },
                requirement = "",
                district = "Dogtown",
                sub_district = "Golden Pacific",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_08_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_08_finished", -- Quest fact for Cyberjunkie death
                container_id = 9001016ULL,         -- Character.cbj_ep1_008_cyberjunkie
                conversation_shard = "Jacqueline Peele and Lucas MacDonald"
            },
            {
                id = "cyberjunkie_andrew_newman",
                name = "Cyberjunkie - Andrew Newman",
                fast_travel = "Luxor High Wellness Spa",
                directions =
                "From the fast travel terminal, face east and enter the abandoned building just opposite the terminal, under the overpass. Head inside and you will find Andrew Newman. Take him out and the shard will be on his body.",
                coords = { x = -1427.0349, y = -2553.0444, z = 85.5436, yaw = -171.1053 },
                requirement = "Balls to the Wall (Side Job) or Firestarter (Main Quest) completed",
                district = "Dogtown",
                sub_district = "Luxor Heights",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_11_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_11_finished", -- Quest fact for Cyberjunkie death
                container_id = 9006626ULL,         -- Character.cbj_ep1_011_cyberjunkie
                conversation_shard = "Andrew Newman and Maxwell Edwards"
            },
        }
    },

    -- ==================================================================================
    -- Category 2: Cyberjunkies
    -- These Cyberjunkies do NOT drop a Cyberware Capacity Shard.
    -- Tracked via kill_fact for completion purposes (defeat = collected).
    -- ==================================================================================
    {
        category = "Cyberjunkies",
        entries = {
            {
                id = "cyberjunkie_maggie_isley",
                name = "Cyberjunkie - Maggie Isley",
                fast_travel = "Terra Cognita",
                directions =
                "Facing the fast travel terminal, turn around and head up the stairs into Terra Cognita. As you pass through the gates, turn left and head up the road. Follow the road until you see the organ building just as you turn the corner. Head up the staircase on the left to the top and around to the greenhouse building. Walk all the way to the end and look up to the right. There is a broken ladder. Jump up and enter through the broken glass roof. Maggie Isley will be inside.",
                coords = { x = -2102.6504, y = -3028.6150, z = 133.2817, yaw = 48.2048 },
                requirement = "",
                district = "Dogtown",
                sub_district = "Terra Cognita",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_02_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_02_finished", -- Quest fact for Cyberjunkie death
                container_id = 9000965ULL,         -- Character.cbj_ep1_002_cyberjunkie (NPC entity: entity-attached mappin; no shard, kill_fact detection)
                conversation_shard = nil
            },
            {
                id = "cyberjunkie_cody_crosby",
                name = "Cyberjunkie - Cody Crosby",
                fast_travel = "Terra Cognita",
                directions =
                "Facing the fast travel terminal, head straight down the road. Look to your right, you will see an abandoned construction site for the High Peak Hotel. Head into the site and towards the crane in between the two buildings. Under the left building, there will be an underground section, Cody Crosby will be there.",
                coords = { x = -1958.6141, y = -2912.6453, z = 90.3754, yaw = 106.1389 },
                requirement = "",
                district = "Dogtown",
                sub_district = "Luxor Heights",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_05_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_05_finished", -- Quest fact for Cyberjunkie death
                container_id = 9000964ULL,         -- Character.cbj_ep1_005_cyberjunkie (NPC entity: entity-attached mappin; no shard, kill_fact detection)
                conversation_shard = nil
            },
            {
                id = "cyberjunkie_david_dover",
                name = "Cyberjunkie - David Dover",
                fast_travel = "Golden Pacific",
                directions =
                "From the fast travel terminal, turn around and head south-west down the road past the Barghest outpost. Head right at the intersection towards the Zhirafa building entrance. Look to your left, there will be a hole in the ground with a truck falling into it. (Look for the headlights hinting the way). There will be a sewer pipe to the right. Head into the sewers, past the mines, David Dover will be in a room on the left.",
                coords = { x = -2086.5623, y = -2518.0886, z = 22.1606, yaw = -179.0323 },
                requirement = "",
                district = "Dogtown",
                sub_district = "Golden Pacific",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_06_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_06_finished", -- Quest fact for Cyberjunkie death
                container_id = 9000967ULL,         -- Character.cbj_ep1_006_cyberjunkie (NPC entity: entity-attached mappin; no shard, kill_fact detection)
                conversation_shard = nil
            },
            {
                id = "cyberjunkie_chester_hamilton",
                name = "Cyberjunkie - Chester Hamilton",
                fast_travel = "Golden Pacific",
                directions =
                "From the fast travel terminal, turn around and head south-west down the road past the Barghest outpost. Head right at the intersection towards the Zhirafa building entrance. On the right will be a parking garage, just to the left before the entrance are some stairs, head down the stairs and Chester Hamilton will be in front of the generators on the right.",
                coords = { x = -2036.9271, y = -2481.5486, z = 24.1655, yaw = 21.1899 },
                requirement = "Defeat Cyberjunkie David Dover and wait 6 in-game hours",
                district = "Dogtown",
                sub_district = "Golden Pacific",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_07_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_07_finished", -- Quest fact for Cyberjunkie death
                container_id = 9006664ULL,         -- Character.cbj_ep1_007_cyberjunkie (NPC entity: entity-attached mappin; no shard, kill_fact detection)
                conversation_shard = nil
            },
            {
                id = "cyberjunkie_sean_mcmillan",
                name = "Cyberjunkie - Sean McMillan",
                fast_travel = "Luxor High Wellness Spa",
                directions =
                "Facing the fast travel terminal, turn left and head towards the ruined building directly in front of you. Follow the road past the building until you see some scaffolding on the right. Use that to climb onto the roof of the building. Sean McMillan will be near the generators on the far side.",
                coords = { x = -1628.2939, y = -2595.3025, z = 96.9565, yaw = -84.2020 },
                requirement = "Defeat any 4 Cyberjunkies.",
                district = "Dogtown",
                sub_district = "Luxor Heights",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_09_active", -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_09_finished",
                container_id = 9006687ULL,         -- Character.cbj_ep1_009_cyberjunkie (NPC entity: entity-attached mappin; no shard, kill_fact detection)
                conversation_shard = nil
            },
            {
                id = "cyberjunkie_greg_wilson",
                name = "Cyberjunkie - Greg Wilson",
                fast_travel = "Luxor High Wellness Spa",
                directions =
                "Facing the fast travel terminal, jump over the railing in front of you and make your way down to the ground level. When you reach the ground level, turn right and head under the overhang. Greg Wilson will be near the homeless shack on the right.",
                coords = { x = -1541.1292, y = -2438.1277, z = 39.7123, yaw = -56.7447 },
                requirement = "Gig: Roads to Redemption completed",
                district = "Dogtown",
                sub_district = "Luxor Heights",
                quest_fact = nil,
                spawn_fact = "cbj_ep1_10_active",  -- Quest fact for Cyberjunkie spawn
                kill_fact = "cbj_ep1_10_finished", -- Quest fact for Cyberjunkie death
                container_id = 9006712ULL,         -- Character.cbj_ep1_010_cyberjunkie (NPC entity: entity-attached mappin; no shard, kill_fact detection)
                conversation_shard = nil
            },
        }
    }
}

-- This makes the table available to any file that 'requires' it
return CyberwareCapacityDB
