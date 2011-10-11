--[[ 
I THOUGHT I SHOULD PROBABLY INCLUDE SOME LICENSING INFORMATION IN THIS
BUT I DON'T REALLY KNOW VERY MUCH ABOUT COPYRIGHT LAW AND IT ALSO SEEMS LIKE MOST
COPYRIGHT NOTICES JUST KIND OF YELL AT YOU IN ALL CAPS. AND APPARENTLY PUBLIC
DOMAIN DOES NOT EXIST IN ALL COUNTRIES, SO I FIGURED I'D STICK THIS HERE SO
YOU KNOW THAT YOU, HENCEFORTH REFERRED TO AS "THE USER" HAVE THE FOLLOWING
INALIABLE RIGHTS:

  0. THE USER can use this piece of poorly written code, henceforth referred to as
    THE SCRIPT, to do the things that it claims it can do.
  1. THE USER should not expect THE SCRIPT to do things that it does not expressly
    claim to be able to do, such as make coffee or print money.
  2. THE USER should realize that starting a list with 0 in a document that
    contains lua code is actually SOMEWHAT IRONIC.
  3. THE WRITER, henceforth referred to as I or ME, depending on the context, holds
    no responsibility for any problems that THE SCRIPT may cause, such as
    if it murders your dog.
  4. THE USER is expected to understand that this is just some garbage that I made
    up and that any and all LEGALLY BINDING AGREEMENTS THAT THE USER HAS AGREED
    TO UPON USAGE OF THE SCRIPT ARE UP TO THE USER TO DISCOVER ON HIS OR HER OWN,
    POSSIBLY THROUGH CLAIRVOYANCE OR MAYBE A SPIRITUAL MEDIUM.
--]]

script_name = "Aegisub-Mocha"
script_description = "Mocha output parser for Aegisub"
script_author = "torque"
script_version = "0.0.0-0.1+2ABF41" -- no, I have no idea how this versioning system works either.
include("karaskel.lua")
include("utils.lua") -- because it saves me like 5 lines of code this way
gui = {}

gui.main = {
  { -- 1 - because it is best if it starts out highlighted.
    class = "textbox";
      x =0; y = 1; height = 4; width = 10;
    name = "mocpat"; hint = "Full path to file. No quotes or escapism needed.";
    text = "e.g.  C:\\path\\to the\\mocha.output"
  },
  { -- 2
    class = "textbox";
      x = 0; y = 17; height = 4; width = 10;
    name = "preerr"; hint = "Any lines that didn't pass the prerun checks are noted here.";
  },
  { -- 3
    class = "label";
      x = 0; y = 0; height = 1; width = 10;
    label = "   Please enter a path to the mocha output. Can only take one file."
  },
  { -- 4
    class = "label";
      x = 0; y = 6; height = 1; width = 10;
    label = "What tracking data should be applied?              Rounding" -- allows more accurate positioning >_>
  },
  { -- 5
    class = "label";
      x = 0; y = 7; height = 1; width = 1;
    label = "Position:"
  },
  { -- 6
    class = "checkbox";
      x = 1; y = 7; height = 1; width = 1;
    value = true; name = "pos"
  },
  { -- 7
    class = "label";
      x = 0; y = 8; height = 1; width = 1;
    label = "Scale:"
  },
  { -- 8
    class = "checkbox";
      x = 1; y = 8; height = 1; width = 1;
    value = true; name = "scl"
  },
  { -- 9
    class = "label";
      x = 0; y = 9; height = 1; width = 1;
    label = "Rotation:"
  },
  { -- 10
    class = "checkbox";
      x = 1; y = 9; height = 1; width = 1;
    value = true; name = "rot"
  },
  { -- 11
    class = "intedit"; -- these are both retardedly wide and retardedly tall. They are downright frustrating to position in the interface.
      x = 7; y = 7; height = 1; width = 3;
    value = 2; name = "pround"; min = 0; max = 5;
  },
  { -- 12
    class = "intedit";
      x = 7; y = 8; height = 1; width = 3;
    value = 2; name = "sround"; min = 0; max = 5;
  },
  { -- 13
    class = "intedit";
      x = 7; y = 9; height = 1; width = 3;
    value = 2; name = "rround"; min = 0; max = 5;
  },
  { -- 15 - yo dawg these numbers is wrong
    class = "label";
      x = 2; y = 8; height = 1; width = 1;
    label = "Border:"
  },
  { -- 16
    class = "checkbox";
      x = 3; y = 8; height = 1; width = 1;
    value = true; name = "bord"
  },
  { -- 17
    class = "label";
      x = 4; y = 8; height = 1; width = 1;
    label = "Shadow:"
  },
  { -- 18
    class = "checkbox";
      x = 5; y = 8; height = 1; width = 1;
    value = true; name = "shad"
  },
  { -- 19
    class = "label";
      x = 0; y = 11; height = 1; width = 10;
    label = "  Enter the file to the path containing your shear/perspective data."
  },
  { -- 20
    class = "textbox";
      x = 0; y = 12; height = 4; width = 10;
    name = "mocper"; hint = "Again, the full path to the file. No quotes or escapism needed.";
    text = "POSITION, SCALE AND ROTATION ARE ALL VALID CHOICES BUT UH I HAVEN'T TESTED ROTATION. AT ALL."
  }
}

gui.halp = {
}

function prerun_czechs(sub, sel, act) -- for some reason, act always returns -1 for me.
  local strt
  for x = 1,#sub do
    if string.find(sub[x].raw,"%[[E|e]vents%]") then -- BECAUSE I SAID SO
      strt = x -- start line of dialogue subs
      break
    end
  end
  aegisub.progress.title("Preparing Gerbils")
  local accd = {}
  local _ = nil
  accd.meta, accd.styles = karaskel.collect_head(sub, false) -- dump everything I need later into the table so I don't have to pass o9k variables to the other functions
  accd.lines = {}
  accd.endframe = aegisub.frame_from_ms(sub[sel[1]].end_time) -- get the end frame of the first selected line
  accd.startframe = aegisub.frame_from_ms(sub[sel[1]].start_time) -- get the start frame of the first selected line
  accd.poserrs, accd.alignerrs = {}, {}
  accd.errmsg = ""
  for i, v in pairs(sel) do -- burning cpu cycles like they were no thing
    local opline = table.copy(sub[v]) -- I have no idea if a shallow copy is even an intelligent thing to do here
    opline.poserrs, opline.alignerrs = {}, {}
    opline.num = v -- this is for, uh, later.
    local _,fx,fy,ali,t_start,t_end,t_exp,t_eff,frz,xbord,ybord,xshad,yshad = nil
    karaskel.preproc_line(sub, accd.meta, accd.styles, opline) -- get that extra position data
    opline.xscl = accd.styles[opline.style].scale_x -- 
    opline.yscl = accd.styles[opline.style].scale_y
    opline.ali = {accd.styles[opline.style].align, false} -- durf
    opline.zrot = accd.styles[opline.style].angle
    opline.xbord = accd.styles[opline.style].outline
    opline.ybord = accd.styles[opline.style].outline
    opline.xshad = accd.styles[opline.style].shadow
    opline.yshad = accd.styles[opline.style].shadow
    for a in string.gfind(opline.text,"%{(.-)%}") do --- this will find comment/override tags yo
      --nothing
    end
    _,_,fx = string.find(opline.text,"\\fscx([%d%.]+)")
    _,_,fy = string.find(opline.text,"\\fscy([%d%.]+)")
    for a in string.gfind(opline.text,"\\an([1-9])") do -- the last \an is the one that is used
      ali = a
    end
    _,_,frz = string.find(opline.text,"\\frz([%-%d%.]+)")
    _,_,bord = string.find(opline.text,"\\bord([%d%.]+)")
    _,_,shad = string.find(opline.text,"\\shad([%-%d%.])")
    _,_,t_start,t_end,t_exp,t_eff = string.find(opline.text,"\\t%(([%-%d]+),?([%-%d]+),?([%d%.]*),?([\\%.%-&%w]+)%)") -- not technically valid because something like t(1.1,\fscx200) will not be captured.
    _,_,opline.xpos,opline.ypos = string.find(opline.text,"\\pos%(([%-%d%.]+),([%-%d%.]+)%)") -- The first \pos is the one that is used
    _,_,opline.xorg,opline.yorg = string.find(opline.text,"\\org%(([%-%d%.]+),([%-%d%.]+)%)") -- idklol
    if fx then opline.xscl = tonumber(fx) end
    if fy then opline.yscl = tonumber(fy) end
    if ali then opline.ali = {tonumber(ali), true} end -- really do need this...?
    if frz then opline.zrot = tonumber(frz) end
    if bord then
      opline.xbord = tonumber(bord)
      opline.ybord = tonumber(bord)
    else -- only check for xbord/ybord if bord is not found (because bord overrides them)
      _,_,xbord = string.find(opline.text,"\\xbord([%d%.]+)") 
      _,_,ybord = string.find(opline.text,"\\ybord([%d%.]+)")
      if xbord then opline.xbord = tonumber(xbord) end -- That was some hilarious bullshit lie and I don't know why I thought that
      if ybord then opline.ybord = tonumber(ybord) end
    end
    if shad then 
      opline.xshad = tonumber(shad)
      opline.yshad = tonumber(shad)
    else
      _,_,xshad = string.find(opline.text,"\\xshad([%-%d%.]+)")
      _,_,yshad = string.find(opline.text,"\\yshad([%-%d%.]+)")
      if xbord then opline.xshad = tonumber(xshad) end -- Yeah seriously I think I was suffering from brain damage or something.
      if ybord then opline.yshad = tonumber(yshad) end
    end
    if not opline.xpos then -- no way it would not find both trololo
      table.insert(accd.poserrs,{i,v})
      accd.errmsg = accd.errmsg..string.format("Line %d does not seem to have a position override tag.\n", v-strt-1)
    end
    --aegisub.log(5,"%d",opline.ali[1])
    if tonumber(opline.ali[1]) ~= 5 then -- the fuck is going on here
      table.insert(accd.alignerrs,{i,v})
      accd.errmsg = accd.errmsg..string.format("Line %d does not seem aligned \\an5.\n", v-strt-1)
    end
    opline.startframe, opline.endframe = aegisub.frame_from_ms(opline.start_time), aegisub.frame_from_ms(opline.end_time)
    if opline.startframe < accd.startframe then -- make timings flexible. Number of frames total has to match the tracked data but
      accd.startframe = opline.startframe
    end
    if opline.endframe > accd.endframe then -- individual lines can be shorter than the whole scene
      accd.endframe = opline.endframe
    end
    table.insert(accd.lines,opline)
    opline.comment = true -- not sure if this is actually a good place to do the commenting or not.
    sub[v] = opline -- comment out the original line
    opline.comment = false -- lines remain commented if cancelled at main dialogue. Oh well, idgaf.
  end
  accd.lvidx, accd.lvidy = aegisub.video_size()
  accd.shx, accd.shy = accd.meta.res_x, accd.meta.res_y
  accd.totframes = accd.endframe - accd.startframe
  accd.toterrs = #accd.alignerrs + #accd.poserrs
  if accd.shx ~= accd.lvidx or accd.shy ~= accd.lvidy then -- check to see if header video resolution is same as loaded video resolution
    accd.errmsg = string.format("Header x/y res (%d,%d) does not match video (%d,%d).\n", accd.shx, accd.shy, accd.lvidx, accd.lvidy)..accd.errmsg
  end
  if accd.toterrs > 0 then
    accd.errmsg = "The lines noted below may need to be checked.\nThe problem lines will be ignored, depending\non what tracking data you choose to apply\n"..accd.errmsg
  else
    accd.errmsg = "None of your selected lines appear to be problematic.\n"..accd.errmsg 
  end
  if #accd.lines == 0 then -- check to see if any of the lines were... selected? If none were, ERROR.
    error("SOMEHOW YOU HAVE SELECTED NO LINES WHATSOEVER. THIS IS AN IMPRESSIVE FEAT")
  end
  init_input(sub,accd)
end

function init_input(sub,accd)
  gui.main[2].text = accd.errmsg -- insert our error messages
  local config
  local opts = 0
  local button = {"Go", "Abort"}
  button, config = aegisub.dialog.display(gui.main, button)
  if button == "Go" then
    aegisub.progress.title("Mincing Gerbils")
    frame_by_frame(sub,accd,config)
    aegisub.set_undo_point("Apply motion data") -- this doesn't seem to actually do anything
  else
    aegisub.progress.task("ABORT")
  end
end

function parse_input(infile)
  local ftab = {}
  local sect, care = 0, 0
  local mocha = {}
  mocha.xpos, mocha.ypos, mocha.xscl, mocha.yscl, mocha.zrot = {}, {}, {}, {}, {}
  for line in io.lines(infile) do
    table.insert(ftab,line) -- dump the lines from the file into a table.
  end
  for keys, valu in pairs(ftab) do -- some really ugly parsing code yo (direct port from my even uglier ruby script).
    val = valu:split("\t")
    if val[1] == "Anchor Point" or val[1] == "Position" or val[1] == "Scale" or val[1] == "Rotation" or val[1] == "End of Keyframe Data" then
      sect = sect + 1
      care = 0
    elseif val[1] == nil then
      care = 0
    else
      care = 1
    end
    if care == 1 and sect == 1 then
      if val[2] ~= "X pixels" then
        table.insert(mocha.xpos,tonumber(val[2])) -- is tonumber() actually necessary? Yes, because the output uses E scientific notation on occasion.
        table.insert(mocha.ypos,tonumber(val[3]))
      end
    elseif care == 1 and sect == 3 then
      if val[2] ~= "X percent" then
        table.insert(mocha.xscl,tonumber(val[2]))
        table.insert(mocha.yscl,tonumber(val[3]))
      end
    elseif care == 1 and sect == 4 then
      if val[2] ~= "Degrees" then
        table.insert(mocha.zrot,tonumber(val[2]))
      end
    end
  end
  mocha.flength = #mocha.xpos
  if mocha.flength == #mocha.ypos and mocha.flength == #mocha.xscl and mocha.flength == #mocha.yscl and mocha.flength == #mocha.zrot then -- make sure all of the elements are the same length (because I don't trust my own code).
    return mocha -- hurr durr
  else
    --return some system crippling error and wonder how the hell mocha's output is messed up
    aegisub.log(0,"The mocha data is not internally equal length. Going into crash mode, t-10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0. Blast off.")
    error("YOU HAVE FUCKED EVERYTHING UP")
  end
end

function frame_by_frame(sub,accd,opts)
  mocha = parse_input(opts.mocpat)
  local _ = nil
  if accd.totframes ~= mocha.flength then -- have to check for total length now that we have time flexibility
    error("Number of frames from selected lines differs from number of frames tracked.")
  end
  local it = 1
  for i,v in ipairs(accd.lines) do
    for k,kv in pairs(v) do
      aegisub.log(5,"%s => %s\n",k,tostring(kv))
    end
    local rstartf = v.startframe - accd.startframe + 1 -- start frame of line relative to start frame of tracked data
    local rendf = v.endframe - accd.startframe -- end frame of line relative to start frame of tracked data
    aegisub.log(5,"%d => %d\n\n", rstartf,rendf)
    if v.xorg and opts.rot then
      v.xorgd, v.yorgd = mocha.xpos[rstartf] - v.xorg, mocha.ypos[rstartf] - v.yorg -- not going to actually use this until I test it more.
      v.zrotd = mocha.zrot[rstartf] - v.zrot
    end
    if v.xpos and opts.pos then
      v.xdiff, v.ydiff = mocha.xpos[rstartf] - v.xpos, mocha.ypos[rstartf] - v.ypos
    end
    local orgtext = v.text -- tables are passed as references.
    if opts.pos and not v.xpos then
      aegisub.log(1,"Line %d is being skipped because it is missing a \\pos() tag and you said to track position. Moron.",v.num) -- yeah that should do it.
    else
      if opts.pos and opts.scl and opts.rot then -- is there conceivably a better way to do this? Yes, move it out of the fucking inner for loop you fucktard
        for x = rstartf,rendf do -- this sure looks a lot more retarded BUT AT LEAST IT RUNS O9k LESS WORTHLESS IF STATEMENTS
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = pos_scl_rot(v,mocha,x,rstartf,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      elseif opts.pos and opts.scl then -- pos + scl
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = pos_scl(v,mocha,x,rstartf,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      elseif opts.pos and opts.rot then -- pos + rot
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = pos_rot(v,mocha,x,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      elseif opts.scl and opts.rot then -- scl + rot
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = scl_rot(v,mocha,x,rstartf,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      elseif opts.pos then -- pos
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = jpos(v,mocha,x,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      elseif not opts.pos then -- scl
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = jscl(v,mocha,x,rstartf,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      elseif not opts.pos then -- rot
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          v.text = jrot(v,mocha,x,opts)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      else
        for x = rstartf,rendf do
          v.start_time = aegisub.ms_from_frame(accd.startframe+x-1)
          v.end_time = aegisub.ms_from_frame(accd.startframe+x)
          sub.insert(v.num+it,v)
          it = it + 1
          v.text = orgtext
        end
      end
    end
  end
end  -- end end end end end end end end end end end end end end end end end end

function jpos(line,mocha,iter,opts)
  local xpos = mocha.xpos[iter]-line.xdiff
  local ypos = mocha.ypos[iter]-line.ydiff
  local tag = string.format("{\\pos(%g,%g)}",round(xpos,opts.pround),round(ypos,opts.pround))
  local newtxt = string.gsub(line.text,"\\pos%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- ONLY ONE POSITION ALLOWED
  newtxt = tag..newtxt
  return newtxt
end

function jscl(line,mocha,iter,rstart,opts) -- I actually have no idea why you would want to do this but WHATEVER
  local tag = string.format("{\\fscx%g\\fscy%g",round(line.xscl,opts.sround),round(line.yscl,opts.sround))
  local newtxt = string.gsub(line.text,"\\fscx([0-9]+%.?[0-9]*)","") -- safe, because it just returns the untouched string if no match
  newtxt = string.gsub(newtext,"\\fscy([0-9]+%.?[0-9]*)","") -- remove all of them because default behavior is to use the last override tag
  if opts.bord then 
    local xbord = line.xbord*round(mocha.xscl[iter]/mocha.xscl[rstart],opts.sround) -- round beforehand to minimize random float errors
    local ybord = line.ybord*round(mocha.yscl[iter]/mocha.yscl[rstart],opts.sround)
    if xbord == ybord then
      tag = tag..string.format("\\bord%g",round(xbord,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xbord,opts.sround),round(ybord,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xbord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\ybord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\bord([0-9]+%.?[0-9]*)","")
  end
  if opts.shad then
    local xshad = line.xshad*round(mocha.xscl[iter]/mocha.xscl[rstart],opts.sround) -- scale shadow the same way as everything else
    local yshad = line.yshad*round(mocha.yscl[iter]/mocha.yscl[rstart],opts.sround) -- hope it turns out as desired
    if xshad == yshad then
      tag = tag..string.format("\\shad%g",round(xshad,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xshad,opts.sround),round(yshad,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\yshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\shad(%-?[0-9]+%.?[0-9]*)","")
  end
  tag = tag.."}"
  newtxt = tag..newtxt
  return newtxt
end

function jrot(line,mocha,iter,opts) -- WHAT HAVE I DONE
  local tag = string.format("{\\org(%g,%g)\\frz%g}",round(mocha.xpos[iter],opts.rround),round(mocha.ypos[iter],opts.rround),round(mocha.zrot[iter]-line.zrotd,opts.rround))
  local newtxt = string.gsub(line.text,"\\org%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- not sure if overwriting the origin is the right thing to do but the one time I tried it it seemed to work well enough >__>
  newtxt = string.gsub(newtxt,"\\frz(%-?[0-9]+%.?[0-9]*)","")
  newtxt = tag..newtxt
end

function pos_scl(line,mocha,iter,rstart,opts)
  local xscl = mocha.xscl[iter]*line.xscl/mocha.xscl[rstart] -- DIVISION IS SLOW
  local yscl = mocha.yscl[iter]*line.yscl/mocha.yscl[rstart]
  local mult = mocha.yscl[iter]/mocha.yscl[rstart] -- wait if xscl and yscl are different then what
  local xpos = mocha.xpos[iter]-(line.xdiff*mult) -- seems to be the right way to do it
  local ypos = mocha.ypos[iter]-(line.ydiff*mult)
  local tag = string.format("{\\pos(%g,%g)\\fscx%g\\fscy%g",round(xpos,opts.pround),round(ypos,opts.pround),round(xscl,opts.sround),round(yscl,opts.sround))
  local newtxt = string.gsub(line.text,"\\fscx([0-9]+%.?[0-9]*)","")
  newtxt = string.gsub(newtxt,"\\fscy([0-9]+%.?[0-9]*)","")
  newtxt = string.gsub(newtxt,"\\pos%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- fuck
  if opts.bord then 
    local xbord = line.xbord*round(mult,opts.sround) -- round beforehand to minimize random float errors
    local ybord = line.ybord*round(mult,opts.sround)
    if xbord == ybord then
      tag = tag..string.format("\\bord%g",round(xbord,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xbord,opts.sround),round(ybord,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xbord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\ybord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\bord([0-9]+%.?[0-9]*)","")
  end
  if opts.shad then
    local xshad = line.xshad*round(mocha.xscl[iter]/mocha.xscl[rstart],opts.sround) -- scale shadow the same way as everything else
    local yshad = line.yshad*round(mocha.yscl[iter]/mocha.yscl[rstart],opts.sround) -- hope it turns out as desired
    if xshad == yshad then
      tag = tag..string.format("\\shad%g",round(xshad,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xshad,opts.sround),round(yshad,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\yshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\shad(%-?[0-9]+%.?[0-9]*)","")
  end
  tag = tag.."}"
  newtxt = tag..newtxt
  return newtxt
end

function pos_rot(line,mocha,iter,opts)
  local xpos = mocha.xpos[iter]-line.xdiff
  local ypos = mocha.ypos[iter]-line.ydiff
  local tag = string.format("{\\pos(%g,%g)\\org(%g,%g)\\frz%g}",round(xbord,opts.sround),round(ybord,opts.sround),round(mocha.xpos[iter],opts.rround),round(mocha.ypos[iter],opts.rround),round(mocha.zrot[iter]-line.zrotd,opts.rround))
  local newtxt = string.gsub(line.text,"\\pos%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","")
  newtxt = string.gsub(newtxt,"\\org%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- idklol
  newtxt = string.gsub(newtxt,"\\frz(%-?[0-9]+%.?[0-9]*)","")
  newtxt = tag..newtxt
  newtxt = tag..newtxt
  return newtxt
end

function scl_rot(line,mocha,iter,rstart,opts) -- This is dumb, and I refuse to test this myself
  local tag = string.format("{\\fscx%g\\fscy%g",round(line.xscl,opts.sround),round(line.yscl,opts.sround))
  local newtxt = string.gsub(line.text,"\\fscx([0-9]+%.?[0-9]*)","") -- choppypasta
  newtxt = string.gsub(newtext,"\\fscy([0-9]+%.?[0-9]*)","")
  newtxt = string.gsub(newtxt,"\\org%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- comment here
  newtxt = string.gsub(newtxt,"\\frz(%-?[0-9]+%.?[0-9]*)","")
  if opts.bord then 
    local xbord = line.xbord*round(mocha.xscl[iter]/mocha.xscl[rstart],opts.sround) -- round beforehand to minimize random float errors
    local ybord = line.ybord*round(mocha.yscl[iter]/mocha.yscl[rstart],opts.sround)
    if xbord == ybord then
      tag = tag..string.format("\\bord%g",round(xbord,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xbord,opts.sround),round(ybord,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xbord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\ybord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\bord([0-9]+%.?[0-9]*)","")
  end
  if opts.shad then
    local xshad = line.xshad*round(mocha.xscl[iter]/mocha.xscl[rstart],opts.sround) -- scale shadow the same way as everything else
    local yshad = line.yshad*round(mocha.yscl[iter]/mocha.yscl[rstart],opts.sround) -- hope it turns out as desired
    if xshad == yshad then
      tag = tag..string.format("\\shad%g",round(xshad,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xshad,opts.sround),round(yshad,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\yshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\shad(%-?[0-9]+%.?[0-9]*)","")
  end
  tag = tag..string.format("\\org(%g,%g)\\frz%g",round(mocha.xpos[iter],opts.rround),round(mocha.ypos[iter],opts.rround),round(mocha.zrot[iter]-line.zrotd,opts.rround))
  tag = tag.."}"
  newtxt = tag..newtxt
  return newtxt
end

function pos_scl_rot(line,mocha,iter,rstart,opts) -- idk if I did this right lolz
  local xscl = mocha.xscl[iter]*line.xscl/mocha.xscl[rstart] -- DIVISION IS SLOW
  local yscl = mocha.yscl[iter]*line.yscl/mocha.yscl[rstart]
  local mult = mocha.yscl[iter]/mocha.yscl[rstart] -- wait if xscl and yscl are different then what
  local xpos = mocha.xpos[iter]-(line.xdiff*mult) -- seems to be the right way to do it
  local ypos = mocha.ypos[iter]-(line.ydiff*mult)
  local tag = string.format("{\\pos(%g,%g)\\fscx%g\\fscy%g",round(xpos,opts.pround),round(ypos,opts.pround),round(xscl,opts.sround),round(yscl,opts.sround))
  local newtxt = string.gsub(line.text,"\\fscx([0-9]+%.?[0-9]*)","")
  newtxt = string.gsub(newtxt,"\\fscy([0-9]+%.?[0-9]*)","")
  newtxt = string.gsub(newtxt,"\\pos%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- fuck
  newtxt = string.gsub(newtxt,"\\org%((%-?[0-9]+%.?[0-9]*),(%-?[0-9]+%.?[0-9]*)%)","") -- not sure if overwriting the origin is the right thing to do but the one time I tried it it seemed to work well enough >__>
  newtxt = string.gsub(newtxt,"\\frz(%-?[0-9]+%.?[0-9]*)","")
  if opts.bord then 
    local xbord = line.xbord*round(mult,opts.sround) -- round beforehand to minimize random float errors
    local ybord = line.ybord*round(mult,opts.sround) -- or maybe that's rly fucking dumb? idklol
    if xbord == ybord then
      tag = tag..string.format("\\bord%g",round(xbord,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xbord,opts.sround),round(ybord,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xbord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\ybord([0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\bord([0-9]+%.?[0-9]*)","")
  end
  if opts.shad then
    local xshad = line.xshad*round(mocha.xscl[iter]/mocha.xscl[rstart],opts.sround) -- scale shadow the same way as everything else
    local yshad = line.yshad*round(mocha.yscl[iter]/mocha.yscl[rstart],opts.sround) -- hope it turns out as desired
    if xshad == yshad then
      tag = tag..string.format("\\shad%g",round(xshad,opts.sround))
    else
      tag = tag..string.format("\\xbord%g\\ybord%g",round(xshad,opts.sround),round(yshad,opts.sround))
    end
    newtxt = string.gsub(newtxt,"\\xshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\yshad(%-?[0-9]+%.?[0-9]*)","")
    newtxt = string.gsub(newtxt,"\\shad(%-?[0-9]+%.?[0-9]*)","")
  end
  tag = tag..string.format("{\\org(%g,%g)\\frz%g}",round(mocha.xpos[iter],opts.rround),round(mocha.ypos[iter],opts.rround),round(mocha.zrot[iter]-line.zrotd,opts.rround)) -- copypasta
  newtxt = tag..newtxt
  tag = tag.."}"
  newtxt = tag..newtxt
  return newtxt
end

function round(num, idp) -- borrowed from the lua-users wiki (all of the intelligent code you see in here is)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function string:split(sep) -- borrowed from the lua-users wiki (single character split ONLY)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

function isvideo() -- a very rudimentary (but hopefully efficient) check to see if there is a video loaded.
  if aegisub.video_size() then return true else return false end
end

aegisub.register_macro("Mocha Parser","Applies motion tracking data collected by Mocha to selected subtitles.", prerun_czechs, isvideo)