require "import"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.net.Uri"
import "android.media.MediaPlayer"
import "android.app.AlertDialog"
import "android.app.ProgressDialog"
import "java.io.File"
import "java.io.FileOutputStream"
import "android.os.Handler"
import "android.speech.tts.TextToSpeech"
import "com.androlua.Http" -- Http library import ki gayi hai

-- Title & Version
local currentVersion = "3.0"
activity.setTitle("BEST TOOL Version " .. currentVersion)

-- File Paths
local localPath = "/storage/emulated/0/解说/Tools/abdul 786/main.lua"
local rawCodeUrl = "https://raw.githubusercontent.com/abdulraufamir559-prog/abdul-786/main/main.lua"
local versionUrl = "https://raw.githubusercontent.com/abdulraufamir559-prog/abdul-786/main/version.txt"

-- ==========================================
--    AUTO UPDATE SYSTEM (IMPROVED)
-- ==========================================
function checkUpdate()
  -- Http.get ka use taaki network error na aaye
  Http.get(versionUrl, function(code, content)
    if code == 200 and content then
      local serverVersion = content:trim()
      if serverVersion ~= currentVersion then
        activity.runOnUiThread(Runnable({
          run=function()
            AlertDialog.Builder(activity)
            .setTitle("Update Available!")
            .setMessage("New Version "..serverVersion.." is ready. Do you want to update?")
            .setPositiveButton("Update Now", {onClick=function() downloadUpdate() end})
            .setNegativeButton("Later", nil)
            .show()
          end
        }))
      end
    else
      print("Update check failed: Server response "..code)
    end
  end)
end

function downloadUpdate()
  local pd = ProgressDialog.show(activity, nil, "Downloading update...")
  Http.get(rawCodeUrl, function(code, content)
    pd.dismiss()
    if code == 200 and content then
      local status, err = pcall(function()
        local file = File(localPath)
        if not file.getParentFile().exists() then file.getParentFile().mkdirs() end
        local out = FileOutputStream(file)
        out.write(content:getBytes())
        out.close()
      end)
      
      if status then
        AlertDialog.Builder(activity)
        .setTitle("Success")
        .setMessage("Update complete! Please restart the tool.")
        .setPositiveButton("OK", {onClick=function() activity.finish() end})
        .show()
      else
        print("Save Error: " .. tostring(err))
      end
    else
      print("Download failed: Error "..code)
    end
  end)
end

-- ==========================================
--    CORE FUNCTIONS & DATA (Baqi Code Same Hai)
-- ==========================================
local prefs = activity.getSharedPreferences("user_data", 0)
local editor = prefs.edit()

function getName() return prefs.getString("name", "") end
function saveName(n) editor.putString("name", n).commit() end
function isSoundEnabled() return prefs.getBoolean("sound_on", true) end

-- Audio Paths
local s_start = "/storage/emulated/0/ApkEditor/tmp/start.mp3"
local s_punch = "/storage/emulated/0/ApkEditor/tmp/punch.mp3"
local s_heal = "/storage/emulated/0/ApkEditor/tmp/H9.ogg"
local s_terror = "/storage/emulated/0/ApkEditor/tmp/terror_scream.mp3"
local s_sweep = "/storage/emulated/0/ApkEditor/tmp/sweeping_blow.mp3"
local s_round_over = "/storage/emulated/0/ApkEditor/tmp/round_over.mp3"
local path_roll = "/storage/emulated/0/Ã§â€˜â„¢Ã¯Â½Ë†Ã®â€¡Â©/Sounds/best/rolldice.mp3"

function playSound(path)
  if isSoundEnabled() then
    pcall(function()
      local mp = MediaPlayer()
      mp.setDataSource(path)
      mp.prepare()
      mp.start()
    end)
  end
end

-- TTS Initialization
local tts
tts = TextToSpeech(activity, TextToSpeech.OnInitListener{
  onInit=function(status)
    if status == TextToSpeech.SUCCESS then tts.setLanguage(Locale.US) end
  end
})

function speak(text)
  if tts and isSoundEnabled() then tts.speak(text, TextToSpeech.QUEUE_FLUSH, nil) end
end

-- ==========================================
--      SURVIVAL ARENA & SNAKE LADDER
-- ==========================================
-- (Arena and Game Logic Code as before...)
local p_health, c_health = 60, 60
local isArenaRunning = false
local arenaHandler = Handler()

function startSurvivalArena()
  p_health, c_health = 60, 60
  isArenaRunning = true
  playSound(s_start)
  speak("Survival Arena started.")
  showArenaUI()
  startMonsterLoop()
end

function showArenaUI()
  local arena_layout = {
    LinearLayout, orientation="vertical", gravity="center", padding="20dp",
    {TextView, text="YOU VS COMPUTER", textSize="22sp", textStyle="bold", textColor="#FF0000"},
    {TextView, id="arena_stats", text="You: 60 | Comp: 60", textSize="18sp", layout_marginTop="10dp"},
    {Button, text="ATTACK COMPUTER", layout_width="fill", layout_marginTop="25dp", onClick=function() 
      if isArenaRunning and p_health > 0 then
        c_health = c_health - 6
        playSound(s_sweep)
        speak("Hit!")
        checkArenaStatus()
      end
    end},
    {Button, text="HEAL (MEDKIT)", layout_width="fill", textColor="#4CAF50", onClick=function() 
      if isArenaRunning and p_health < 60 then
        p_health = p_health + 12
        if p_health > 60 then p_health = 60 end
        playSound(s_heal)
        speak("Healed")
        checkArenaStatus()
      end
    end},
    {Button, text="Back to Menu", layout_width="fill", layout_marginTop="35dp", onClick=function() 
      isArenaRunning = false
      showMenu() 
    end}
  }
  activity.setContentView(loadlayout(arena_layout))
end

function startMonsterLoop()
  arenaHandler.postDelayed(Runnable({
    run=function()
      if isArenaRunning and p_health > 0 and c_health > 0 then
        p_health = p_health - 8
        playSound(s_punch)
        speak("Computer hit you!")
        checkArenaStatus()
        if isArenaRunning then startMonsterLoop() end
      end
    end
  }), 3500)
end

function checkArenaStatus()
  if p_health <= 0 then
    isArenaRunning = false
    playSound(s_round_over)
    speak("You lost!")
    showRes("Game Over")
  elseif c_health <= 0 then
    isArenaRunning = false
    playSound(s_round_over)
    speak("You won!")
    showRes("Victory!")
  end
  if arena_stats then arena_stats.setText("You: "..p_health.." | Comp: "..c_health) end
end

function showRes(m)
  AlertDialog.Builder(activity).setTitle(m).setCancelable(false)
  .setPositiveButton("Restart", {onClick=function() startSurvivalArena() end})
  .setNegativeButton("Menu", {onClick=function() showMenu() end}).show()
end

-- ==========================================
--        SNAKE & LADDER GAME
-- ==========================================
local pos, c_pos = 1, 1
local snakes={[16]=6,[47]=26,[49]=11,[56]=53,[62]=19,[64]=60,[87]=24,[93]=73,[95]=75,[98]=78}
local ladders={[1]=38,[4]=14,[9]=31,[21]=42,[28]=84,[36]=44,[51]=67,[71]=91,[80]=100}

function showSL()
  pos, c_pos = 1, 1
  local sl_layout = {
    LinearLayout, orientation="vertical", gravity="center", padding="20dp",
    {TextView, text="Snake & Ladder", textSize="22sp"},
    {TextView, id="sl_txt", text="You: 1 | Comp: 1", textSize="18sp"},
    {Button, id="roll_btn", text="Roll Dice", layout_width="fill", onClick=function()
       playSound(path_roll)
       local d = math.random(1,6)
       pos = pos + d
       if pos >= 100 then speak("You won") showMenu() return end
       if snakes[pos] then pos = snakes[pos] speak("Snake!") elseif ladders[pos] then pos = ladders[pos] speak("Ladder!") end
       speak("You rolled "..d)
       roll_btn.setEnabled(false)
       Handler().postDelayed(Runnable({run=function()
         local cd = math.random(1,6)
         c_pos = c_pos + cd
         if c_pos >= 100 then speak("Computer won") showMenu() return end
         if snakes[c_pos] then c_pos = snakes[c_pos] end
         speak("Computer rolled "..cd)
         if sl_txt then sl_txt.setText("You: "..pos.." | Comp: "..c_pos) end
         roll_btn.setEnabled(true)
       end}), 2000)
    end},
    {Button, text="Back", layout_width="fill", onClick=showMenu}
  }
  activity.setContentView(loadlayout(sl_layout))
end

-- ==========================================
--        MAIN MENU
-- ==========================================
function showMenu()
  local name = getName()
  if name == "" then askName() return end
  local menu_layout = {
    LinearLayout, orientation="vertical", gravity="center", padding="20dp",
    {TextView, text="BEST TOOL v"..currentVersion.."\nWelcome " .. name, textSize="20sp", gravity="center", textColor="#2196F3"},
    {Button, text="Survival Arena (1vs1)", layout_width="fill", layout_marginTop="20dp", onClick=startSurvivalArena},
    {Button, text="Snake & Ladder", layout_width="fill", onClick=showSL},
    {Button, text="Check for Updates", layout_width="fill", onClick=checkUpdate},
    {Button, text="Exit", layout_width="fill", onClick=function() activity.finish() end}
  }
  activity.setContentView(loadlayout(menu_layout))
end

function askName()
  local input = EditText(activity)
  AlertDialog.Builder(activity).setTitle("Enter Name").setView(input).setCancelable(false)
  .setPositiveButton("Save", {onClick=function()
    local n = input.getText().toString()
    if n~="" then saveName(n) showMenu() speak("Welcome") else askName() end
  end}).show()
end

-- FINAL START
checkUpdate()
if getName()=="" then askName() else showMenu() end