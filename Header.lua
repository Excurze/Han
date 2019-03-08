return {
    id = 'Singed'; -- ID of script
    name = 'EXSinged'; -- Name of script. Will be displayed in HanBot Menu
    riot = true; -- Riot Region = true
    load = function() --Loads champion code from main
      return player.charName == "Singed" --Checks Champ
    end;
    type = "Champion"; --Type of script
  }