-- This information tells other players more about the mod
name = "Item Meta"
description = "Displays extra metadata in item tooltips."
author = "Alberto Pietralunga, based on DST code by Gimmeh"

version = "1.0.0"
forumthread = ""

api_version = 6
dont_starve_compatible      = true
reign_of_giants_compatible  = true
shipwrecked_compatible      = true
hamlet_compatible           = true

-- Custom icon
icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- Configuration options
configuration_options =
{
    {
        name = "FOOD_FORMAT",
        label = "Food Format",
        options = {
            {description = "Horizontal", data = "h"},
            {description = "Vertical", data = "v"},
        },
        default = "h",
    },
    {
        name = "FOOD_ORDER",
        label = "Food Order",
        options = {
            {description = "hu/he/sa", data = "hu/he/sa"},
            {description = "hu/sa/he", data = "hu/sa/he"},
            {description = "he/hu/sa", data = "he/hu/sa"},
        },
        default = "hu/he/sa",
    },
}
