-- ======================================================================================
-- Mod Name: Cyberware Capacity Shard Checklist
-- Author: Spuddeh
-- Description: Database of fixed Cyberware Capacity Shard locations in Dogtown.
-- Mod Version: 1.0.0
-- ======================================================================================

local CyberwareCapacityDB = {
    {
        category = "Dogtown",
        entries = {
            {
                id = "dogtown_stadium_cache",
                name = "Stadium Parking Garage (Cache)",
                fast_travel = "Stadium Parking",
                directions =
                "During the 'Dog Eat Dog' intro mission, right after stepping off the elevator into the garage. Look for a container in the main parking garage of the EBM Petrochem Stadium.\n\n---!!!POTENTIALLY MISSABLE!!!---\nThis shard is in the same area as the PSC shard. If you miss it during the mission, there may not be a way to return.",
                coords = { x = 0, y = 0, z = 0, yaw = 0 }, -- TBD via Inspector
                requirement = "Dog Eat Dog",
                district = "Dogtown",
                sub_district = "Stadium",

                -- Automation Keys (TBD via Inspector)
                quest_fact = nil,
                container_id = nil
            },
            {
                id = "dogtown_terra_cognita",
                name = "Terra Cognita (Wesley Hunt)",
                fast_travel = "", -- TBD
                directions =
                "Dropped by Wesley Hunt, a Cyberjunkie NPC found at the Anatomicon in the Terra Cognita district of Dogtown.",
                coords = { x = 0, y = 0, z = 0, yaw = 0 }, -- TBD via Inspector
                requirement = "",
                district = "Dogtown",
                sub_district = "Terra Cognita",

                -- Automation Keys (TBD via Inspector)
                quest_fact = nil,
                container_id = nil
            },
            {
                id = "dogtown_longshore_court",
                name = "Longshore Stacks (Jacob Bernard)",
                fast_travel = "Longshore Stacks",
                directions =
                "Dropped by Jacob Bernard, a Cyberjunkie NPC found near a basketball court in the Longshore Stacks area of Dogtown.",
                coords = { x = 0, y = 0, z = 0, yaw = 0 }, -- TBD via Inspector
                requirement = "",
                district = "Dogtown",
                sub_district = "Longshore Stacks",

                -- Automation Keys (TBD via Inspector)
                quest_fact = nil,
                container_id = nil
            },
            {
                id = "dogtown_golden_pacific_atlas",
                name = "Golden Pacific (Garry Bates)",
                fast_travel = "", -- TBD
                directions =
                "Dropped by Garry Bates, a Cyberjunkie NPC found at the Brave Atlas in the Golden Pacific district of Dogtown.",
                coords = { x = 0, y = 0, z = 0, yaw = 0 }, -- TBD via Inspector
                requirement = "",
                district = "Dogtown",
                sub_district = "Golden Pacific",

                -- Automation Keys (TBD via Inspector)
                quest_fact = nil,
                container_id = nil
            },
            {
                id = "dogtown_golden_pacific_alley",
                name = "Golden Pacific (Jacqueline Peele)",
                fast_travel = "", -- TBD
                directions =
                "Dropped by Jacqueline Peele, a Cyberjunkie NPC found in an alley to the west of the Black Sapphire in the Golden Pacific district of Dogtown.",
                coords = { x = 0, y = 0, z = 0, yaw = 0 }, -- TBD via Inspector
                requirement = "",
                district = "Dogtown",
                sub_district = "Golden Pacific",

                -- Automation Keys (TBD via Inspector)
                quest_fact = nil,
                container_id = nil
            },
            {
                id = "dogtown_stadium_parking",
                name = "Stadium Parking (Andrew Newman)",
                fast_travel = "EBM Petrochem Stadium",
                directions =
                "Dropped by Andrew Newman, a Cyberjunkie NPC found near the entrance of the abandoned Petrochem parking lot, near the Luxor High Wellness Spa.",
                coords = { x = 0, y = 0, z = 0, yaw = 0 }, -- TBD via Inspector
                requirement = "",
                district = "Dogtown",
                sub_district = "Stadium",

                -- Automation Keys (TBD via Inspector)
                quest_fact = nil,
                container_id = nil
            },
        }
    }
}

-- This makes the table available to any file that 'requires' it
return CyberwareCapacityDB
