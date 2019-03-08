local orb = module.internal("orb")
local evade = module.internal("evade")
local pred = module.internal("pred")
local ts = module.internal("TS")
local common = module.load("Singed", "common")

-------------------
-- Menu creation --
-------------------

local menu = menu("Singed", "EXSinged")
menu:menu("laneclear", "Farming")
menu.laneclear:keybind("toggle", "Farm Toggle", "Z", nil)
menu.laneclear:menu("push", "Lane Clear")
menu.laneclear.push:slider("mana", "Mana Manager", 30, 0, 100, 1)
menu.laneclear.push:boolean("useq", "Use Q to Farm", true)
menu:menu("w", "W Settings")
menu.w:boolean("use_w", "Use W", true)
menu:menu("e", "E Settings")
menu.e:boolean("use_e", "Use E", true)
menu:menu("keys", "Key Settings")
menu.keys:keybind("combokey", "Combo Key", "Space", nil)
menu.keys:keybind("harasskey", "Harass Key", "C", nil)
menu.keys:keybind("clearkey", "Lane Clear Key", "V", nil)
menu.keys:keybind("lastkey", "Last Hit", "X", nil)
ts.load_to_menu()
local daze = false
local Healer = 0

local function Toggle()
  if menu.laneclear.toggle:get() then
    if (daze == false and os.clock() > Healer) then
      daze = true
      something = os.clock() + 0.3
    end
    if (daze == true and os.clock() > something) then
      daze = false
      Healer = os.clock() + 0.3
    end
  end
end

-------------------
--- Spell data ----
-------------------

local WRange = 1000
local ERange = 125

local WPred = {delay = 0.5, radius = 280, speed = 700}
local EPred = {}

--- W ---

local W_Spell_Pos = nil

local function CreateObj(object)
  if object and object.name then
    if object.name:find("W_green_pool") then
      W_Spell_Pos = object
    end
  end
end

local function DeleteObj(object)
  if W_Spell_Pos and W_Spell_Pos.name == object.name then
    W_Spell_Pos = nil
  end
end
-------------------------------
-- Target selector functions --
-------------------------------

local function w_target(res, obj, dist)
  if dist > WRange then
    return
  end

  res.obj = obj
  return true
end

local function e_target(res, obj, dist)
  if dist > ERange then
    return
  end

  res.obj = obj
  return true
end

local function get_target(func)
  return ts.get_result(func).obj
end

local function count_minions_in_range(pos, range)
  local enemies_in_range = {}
  for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
    local enemy = objManager.minions[TEAM_ENEMY][i]
    if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
      enemies_in_range[#enemies_in_range + 1] = enemy
    end
  end
  return enemies_in_range
end
-----------
-- Combo --
-----------


local function LaneClear()
  if daze then
    return
  end
  if (player.mana / player.maxMana) * 100 >= menu.laneclear.push.mana:get() then
    if menu.laneclear.push.useq:get() then
      for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if
          minion and minion.isVisible and minion.isTargetable and not minion.isDead and
            (#count_minions_in_range(player.pos, 500) >= 1)
         then
          if menu.keys.clearkey:get() then
            if player.buff["poisontrail"] then
            end
            if not player.buff["poisontrail"] then
              player:castSpell("self", 0)
            end
          end
        end
      end
    end
  end
end

local function Combo()
  local w = player:spellSlot(1).state == 0
  local e = player:spellSlot(2).state == 0

  if menu.w.use_w:get() then
    local target = get_target(w_target)
    if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
      if w and target.pos:dist(player.pos) <= WRange then
        local seg = pred.circular.get_prediction(WPred, target)
        player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
      end
    end
  end
  if menu.e.use_e:get() then
    local target = get_target(e_target)
    if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
      
      player:castSpell("obj", 2, target)
    ---player:castSpell("pos", 2, W_Spell_pos)
        end
    end
  end


-----------
-- Hooks --
-----------

local function ontick()
  if menu.keys.combokey:get() then
    Combo()
  end
  if menu.keys.clearkey:get() then
    LaneClear()
  end
  if not menu.keys.clearkey:get() and not menu.keys.combokey:get() and player.buff["poisontrail"] then
    player:castSpell("self", 0)
  end
end

local function ondraw()
  if menu.w.use_w:get() then
    graphics.draw_circle(player.pos, WRange, 2, graphics.argb(255, 168, 0, 157), 50)
  end
  if menu.e.use_e:get() then
    graphics.draw_circle(player.pos, ERange, 2, graphics.argb(255, 168, 0, 157), 50)
  end
  if W_Spell_Pos then
    graphics.draw_circle(W_Spell_Pos, WPred.radius, 2, graphics.argb(255, 0, 255, 0), 50)
  end
end

cb.add(cb.create_particle, CreateObj)
cb.add(cb.delete_particle, DeleteObj)
orb.combat.register_f_pre_tick(ontick)
cb.add(cb.draw, ondraw)
