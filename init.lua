local modstorage = minetest.get_mod_storage()
 
local pattern = {}
local pattern2 = {}

local startup = function()
    local temp = {}
    if modstorage:get_int("startup") ~= 1 then
        for i = 1, 64, 1 do
            minetest.log("error","insert")
            table.insert(temp,math.random(1,i),i)
            minetest.chat_send_all("inserted")
        end
        for i = 1, 64, 1 do
            modstorage:set_int(i,temp[i])
            minetest.chat_send_all("saved")
        end
    else
        for i = 1, 64, 1 do
            temp[i]=modstorage:get_int(i)
        end
    end
    minetest.log("error",dump(temp))
    modstorage:set_int("startup",1)
    minetest.chat_send_all("doing startup")
   
    local abc = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    local i = 1
    for _,v in pairs(temp) do
        pattern[string.sub(abc,i,i)] = v
        pattern2[v] = string.sub(abc,i,i)
        i = i +1
    end
end

local use_power = function(pos,amount)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack("fuelslot",1)
	local fuel = meta:get_int("fuel")
	local rawfuel
	if stack:get_name() == "portaltest:blue_mese" then
		rawfuel = stack:get_count() * 900*50
	elseif stack:get_name() == "portaltest:red_mese" then
		rawfuel = stack:get_count() * 300*50
	else
		rawfuel = stack:get_count() * 15*50
	end
	
	if fuel >= amount then
		meta:set_int("fuel",fuel-amount)
		return true
	elseif fuel + rawfuel >= amount then
		local dif = amount-fuel
		if stack:get_name() == "portaltest:blue_mese" then
			dif = math.ceil(dif/(900*50))
			stack:set_count(stack:get_count()-dif)
			meta:set_int("fuel",fuel+(dif*900*50)-amount)
		elseif stack:get_name() == "portaltest:red_mese" then
			dif = math.ceil(dif/(300*50))
			stack:set_count(stack:get_count()-dif)
			meta:set_int("fuel",fuel+(dif*300*50)-amount)
		else
			dif = math.ceil(dif/(15*50))
			stack:set_count(stack:get_count()-dif)
			meta:set_int("fuel",fuel+(dif*15*50)-amount)
		end
		inv:set_stack("fuelslot",1,stack)
		return true
	end
	return false
end

local is_allowed = function(adress)
	if adress:len() ~= 7 then return false end
	for i = 1, string.len(adress), 1 do
		if pattern[string.sub(adress,i,i)] == nil then
			return false
		end
	end
	return true
end

local function get_far_node(pos)
    local node = minetest.get_node(pos)
    if node.name == "ignore" then
        minetest.get_voxel_manip():read_from_map(pos, pos)
        node = minetest.get_node(pos)
    end
    return node
end

local get_blocks = function(pos)
    local blocks = {}
    table.insert(blocks,vector.add(pos,vector.new(1,0,0)))
    table.insert(blocks,vector.add(pos,vector.new(2,0,0)))
    table.insert(blocks,vector.add(pos,vector.new(-1,0,0)))
    table.insert(blocks,vector.add(pos,vector.new(-2,0,0)))
    table.insert(blocks,vector.add(pos,vector.new(2,1,0)))
    table.insert(blocks,vector.add(pos,vector.new(2,2,0)))
    table.insert(blocks,vector.add(pos,vector.new(2,3,0)))
    table.insert(blocks,vector.add(pos,vector.new(2,4,0)))
    table.insert(blocks,vector.add(pos,vector.new(-2,1,0)))
    table.insert(blocks,vector.add(pos,vector.new(-2,2,0)))
    table.insert(blocks,vector.add(pos,vector.new(-2,3,0)))
    table.insert(blocks,vector.add(pos,vector.new(-2,4,0)))
    table.insert(blocks,vector.add(pos,vector.new(1,4,0)))
    table.insert(blocks,vector.add(pos,vector.new(-1,4,0)))
    table.insert(blocks,vector.add(pos,vector.new(0,0,1)))
    table.insert(blocks,vector.add(pos,vector.new(0,0,2)))
    table.insert(blocks,vector.add(pos,vector.new(0,0,-1)))
    table.insert(blocks,vector.add(pos,vector.new(0,0,-2)))
    table.insert(blocks,vector.add(pos,vector.new(0,1,2)))
    table.insert(blocks,vector.add(pos,vector.new(0,2,2)))
    table.insert(blocks,vector.add(pos,vector.new(0,3,2)))
    table.insert(blocks,vector.add(pos,vector.new(0,4,2)))
    table.insert(blocks,vector.add(pos,vector.new(0,1,-2)))
    table.insert(blocks,vector.add(pos,vector.new(0,2,-2)))
    table.insert(blocks,vector.add(pos,vector.new(0,3,-2)))
    table.insert(blocks,vector.add(pos,vector.new(0,4,-2)))
    table.insert(blocks,vector.add(pos,vector.new(0,4,1)))
    table.insert(blocks,vector.add(pos,vector.new(0,4,-1)))
    table.insert(blocks,vector.add(pos,vector.new(0,4,0)))
    return blocks
end

local decode = function(id)
    local b = 0
    local adress = ""
    for i = 5,0,-1 do
        b = math.floor(id/64^i)
        adress=adress..pattern2[b+1]
        id = id % 64^i
    end
    return adress
end

local adress_to_id = function(adress)
    if string.len(adress) ~= 7 then
        minetest.chat_send_all(adress.."     "..string.len(adress))
        return
    end
   
    local id = 0
    for i = 1 , 6 , 1 do
        id = id + (pattern[adress:sub(i,i)]-1)*(64^(6-i))
    end
    return id
end

local get_mb_id = function(mb)
    local id = (mb.x+2048) * (4096^2) + (mb.z+2048) * (4096) + (mb.y+2048)
    return id
end

local id_to_mb = function(id)
	if id == nil then
		return false
	end
    local x,y,z
    x = math.floor(id / (4096^2))
    id = id - x * (4096^2)
    z = math.floor(id / 4096)
    id = id - z * 4096
    y = id
    return vector.new(x-2048,y-2048,z-2048)
end

local pos_to_mb = function(pos)
    local x,y,z
    x = math.floor(pos.x / 16)
    y = math.floor(pos.y / 16)
    z = math.floor(pos.z / 16)
    return vector.new(x,y,z)
end

local find_gate = function(mb,id)
	if mb == false then
		return false
	end

    local x,y,z,xid,yid,zid,block
    x = mb.x * 16
    y = mb.y * 16
    z = mb.z * 16
    xid = math.floor(id / 16) + 1
    id = id - (xid-1) * 16
    zid = math.floor(id / 4) + 1
    id = id - (zid-1) * 4
    yid = id + 1
    block = minetest.find_nodes_in_area(vector.new(x+(4*(xid-1)),y+(4*(yid-1)),z+(4*(zid-1))),vector.new(x+(4*xid),y+(4*yid),z+(4*zid)),"portaltest:core")[1]
    if block ~= nil then
        return block
    else
        return false
    end
end

local rotate = function(obj)
	if obj:is_player() then
		obj:set_look_horizontal(obj:get_look_horizontal()+(math.pi/2))
	end
end

local get_structure = function(dir,pos)
    local blocks = {}
    local a,b
    blocks = get_blocks(pos)
    if dir == "x" then
        a = 1
        b = 14
    elseif dir == "z" then
        a = 15
        b = 28
    else
        return false
    end
    for m = a, b ,1 do
        if get_far_node(blocks[m]).name ~= "portaltest:structblock" then
            return false
        end
    end
    if get_far_node(blocks[29]).name ~= "portaltest:structblock" then
        return false
    end
    for m = a, b ,1 do
        minetest.set_node(blocks[m],{name = "portaltest:portalstructure"})
    end
    minetest.set_node(blocks[29],{name = "portaltest:portalstructure"})
    return true
end

local place_portal = function(pos,dir,block)
    if dir == "x" then
        for y = 1,3,1 do
            for x = -1,1,1 do
                minetest.set_node(vector.add(pos,vector.new(x,y,0)),{name=block})
            end
        end
    else
        for y = 1,3,1 do
            for z = -1,1,1 do
                minetest.set_node(vector.add(pos,vector.new(0,y,z)),{name=block})
            end
        end
    end
end

local dial = function(pos,adress)
    local meta = minetest.get_meta(pos)
	minetest.get_voxel_manip():read_from_map(vector.multiply(id_to_mb(adress_to_id(adress)),16), vector.add(vector.multiply(id_to_mb(adress_to_id(adress)),16),vector.new(15,15,15)))
    if meta:get_int("active") == 1 or not 
	is_allowed(adress) then
        meta:set_int("active",0)
		adress = meta:get_string("adress")
        place_portal(pos,meta:get_string("dir"),"portaltest:air")
        local dest = find_gate(id_to_mb(adress_to_id(adress)),pattern[string.sub(adress,7,7)]-1)
        place_portal(dest,minetest.get_meta(dest):get_string("dir"),"portaltest:air")
		local dmeta = minetest.get_meta(dest)
		dmeta:set_int("active",0)
        return
    end
    if #adress ~= 7 then
        return
    end
    if meta:get_int("complete") == 0 then
        return
    end
    local dest = find_gate(id_to_mb(adress_to_id(adress)),pattern[string.sub(adress,7,7)]-1)
    if dest == false then
        return
    end

    local dmeta = minetest.get_meta(dest)
    if dmeta:get_int("active") == 0 then
		if use_power(pos,75*50) then
			meta:set_int("active",1)
			dmeta:set_int("active",1)
			meta:set_string("adress",adress)
			dmeta:set_string("adress",meta:get_string("ownadress"))
			place_portal(pos,meta:get_string("dir"),"portaltest:portal")
			place_portal(dest,dmeta:get_string("dir"),"portaltest:dportal")
			minetest.add_entity(vector.add(pos,vector.new(0,2,0)),"portaltest:portalent")
			minetest.forceload_block(vector.add(pos,vector.new(0,2,0)))
		end
    end
end

local destroy_gate = function(dir,pos)
	local meta = minetest.get_meta(pos)
	if meta:get_int("active") == 1 then
		dial(pos, meta:get_string("adress"))
	end
    local blocks = {}
    local a,b
    blocks = get_blocks(pos)
    if dir == "x" then
        a = 1
        b = 14
    elseif dir == "z" then
        a = 15
        b = 28
    else
        return false
    end
    for m = a, b ,1 do
        if get_far_node(blocks[m]).name == "portaltest:portalstructure" then
            minetest.set_node(blocks[m],{name = "portaltest:structblock"})
        end
    end
    if get_far_node(blocks[29]).name == "portaltest:portalstructure" then
        minetest.set_node(blocks[29],{name = "portaltest:structblock"})
    end
end

local get_status = function(pos)
return minetest.get_meta(pos):get_int("active")==1
end

local get_adress = function(pos)
  local mbpos = pos_to_mb(pos)
  mbpos = vector.multiply(mbpos,16)
  mbpos = vector.subtract(pos,mbpos)
  mbpos = vector.divide(mbpos,4)
  return decode(get_mb_id(pos_to_mb(pos)))..pattern2[(math.floor(mbpos.x)*16+math.floor(mbpos.z)*4+math.floor(mbpos.y)+1)]
end

local get_dest = function(pos)
  return minetest.get_meta(pos):get_string("adress")
end

local get_fav = function(pos)
	return string.split(minetest.get_meta(pos):get_string("fav"),"<",-1,false)
end

local function find_fav(pos, fav)
  for key, value in pairs(get_fav(pos)) do
    if fav == value then
      return true
    end
  end
end

local function double_fav(pos, adress)
  for key, value in pairs(get_fav(pos)) do
    if adress == string.sub(value, -7) then
      return string.sub(value, 1, string.len(value) - 8)
    end
  end
end

local add_fav = function(pos,fav)
	if not is_allowed(string.sub(fav,-7)) then
		return
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("fav",meta:get_string("fav").."<"..fav)
	if string.sub(meta:get_string("fav"),1,1) == "<" then
		meta:set_string("fav",string.sub(meta:get_string("fav"),2))
	end
end

local remove_fav = function(pos,fav)
	local meta = minetest.get_meta(pos)
	local favs = string.split(meta:get_string("fav"),"<",-1,false)
	local temp = ""
	for _,v in pairs(favs) do
		if v ~= fav then
			temp = temp .."<".. v
		end
	end
	meta:set_string("fav",string.sub(temp,2))
end

local function formspec(pos, player, placeholdername, placeholderadresse)
  if get_status(pos) then
    local portalname = "Portalname"
    local exist = double_fav(pos, get_dest(pos))
    if exist ~= nil then
      portalname = exist
    end
    minetest.show_formspec(player:get_player_name(), "portaltest:portalon", 
      "size[5.4,3]" ..
      "label[2.34,0;".. get_adress(pos) .."]" ..
      "box[0,0;5.2,0.4;#40ff00]" ..
      "field[0.3,1;3.2,0.5;name;;".. portalname .."]" ..
      "field[0.3,1.9;3.2,0.5;adresse;;".. get_dest(pos) .. "]" ..
      "field[0,0;0,0;posx;;"..pos.x.."]"..
      "field[0,0;0,0;posy;;"..pos.y.."]"..
      "field[0,0;0,0;posz;;"..pos.z.."]"..
      "button[0,2.25;1.1,1;addbutton;+ Portal]" ..
      "button[1.05,2.25;1.1,1;teleportbutton;Teleport]" ..
      "button[2.1,2.25;1.1,1;removebutton;- Portal]" ..
      "table[3.2,0.54;2,2.5;table;".. table.concat(get_fav(pos), ",") ..";]")
  else
    local portalname = "Portalname"
    local portaladresse = "Portaladresse"
    if placeholdername ~= nil then
      portalname = placeholdername
    end
    if placeholderadresse ~= nil then
      portaladresse = placeholderadresse
    end
      minetest.show_formspec(player:get_player_name(), "portaltest:portaloff", 
      "size[5.4,3]" ..
      "label[2.34,0;".. get_adress(pos) .."]" ..
      "box[0,0;5.2,0.4;#ff0000]" ..
      "field[0.3,1;3.2,0.5;name;;".. portalname .."]" ..
      "field[0.3,1.9;3.2,0.5;adresse;;".. destination .."]" ..
      "field[0,0;0,0;posx;;"..pos.x.."]"..
      "field[0,0;0,0;posy;;"..pos.y.."]"..
      "field[0,0;0,0;posz;;"..pos.z.."]"..
      "button[0,2.25;1.1,1;addbutton;+ Portal]" ..
      "button[1.05,2.25;1.1,1;teleportbutton;Teleport]" ..
      "button[2.1,2.25;1.1,1;removebutton;- Portal]" ..
      "table[3.2,0.54;2,2.5;table;".. table.concat(get_fav(pos), ",") ..";]")
    end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "portaltest:portalon" or formname == "portaltest:portaloff" then
    local pos = {x = tonumber(fields.posx), y = tonumber(fields.posy), z = tonumber(fields.posz)}
    if fields.teleportbutton then
		if not is_allowed(fields.adresse) then return end
		dial(pos, fields.adresse)
    end
    if fields.addbutton and fields.name ~= "" and fields.name ~= "Portalname" and string.len(fields.adresse) == 7 and double_fav(pos, fields.adresse) == nil then
		add_fav(pos, fields.name ..":".. fields.adresse)
		formspec(pos, player)
    end
    if fields.removebutton and find_fav(pos, fields.name ..":".. fields.adresse) then
		remove_fav(pos, fields.name ..":".. fields.adresse)
		formspec(pos, player)
    end
    if fields.table then
		local selected = fields.table
		if selected:sub(1,3) == "CHG" then
			local fav = get_fav(pos)[tonumber(selected:sub(5, -3))]
			formspec(pos, player, string.sub(fav, 1, string.len(fav) - 8), string.sub(fav, -7))
		end
    end
	end
end)

minetest.register_entity("portaltest:portalent",{
    hp_max = 1,
    physical = false,
    weight = 0,
    is_visible = false,
    collisionbox = {0,0,0,0,0,0},
    on_step = function(self,dtime)
        local pos = self.object:getpos()
        if minetest.get_node(pos).name ~= "portaltest:portal" or get_far_node(vector.add(pos,vector.new(0,-2,0))).name ~= "portaltest:core" then
			minetest.chat_send_all("portalent removed")
            self.object:remove()
            minetest.forceload_free_block(pos)
            return
        end
		local adress = minetest.get_meta(vector.add(pos,vector.new(0,-2,0))):get_string("adress")
		if not use_power(vector.add(pos,vector.new(0,-2,0)),1) then
			dial(vector.add(pos,vector.new(0,-2,0)),adress)
			minetest.chat_send_all("portalent removed")
            self.object:remove()
            minetest.forceload_free_block(pos)
            return
		end
        local dir = minetest.get_meta(vector.add(pos,vector.new(0,-2,0))):get_string("dir")
        local objs = minetest.get_objects_inside_radius(pos,2.2)

		minetest.get_voxel_manip():read_from_map(vector.multiply(id_to_mb(adress_to_id(adress)),16), vector.add(vector.multiply(id_to_mb(adress_to_id(adress)),16),vector.new(15,15,15)))
        local dpos = find_gate(id_to_mb(adress_to_id(adress)),pattern[string.sub(adress,7,7)]-1)
		if dpos == false then
			return
		end
        dmeta = minetest.get_meta(dpos)
        dpos = vector.add(dpos,vector.new(0,2,0))
        for _,obj in pairs(objs) do
			if vector.distance(self.object:getpos() , obj:getpos()) ~= 0 then
				local ab = vector.subtract(obj:getpos(),pos)
				if dir == "x" then
					if ab.x <= 1.5 and ab.x >=-1.5 and ab.z <= 0.5 and ab.z >= -0.5 and ab.y <= 1.5 and ab.y >= -1.5 then
						if use_power(vector.add(pos,vector.new(0,-2,0)),6*50) then
							if dmeta:get_string("dir") == "x" then
								obj:setpos(vector.add(dpos,ab))
							else
								obj:setpos(vector.add(dpos,vector.new(ab.z,ab.y,ab.x)))
								rotate(obj)
							end
						end
					end
				else
					if ab.x <= 0.5 and ab.x >=-0.5 and ab.z <= 1.5 and ab.z >= -1.5 and ab.y <= 1.5 and ab.y >= -1.5 then
						if use_power(vector.add(pos,vector.new(0,-2,0)),6*50) then
							if dmeta:get_string("dir") == "x" then
								obj:setpos(vector.add(dpos,ab))
								rotate(obj)
							else
								obj:setpos(vector.add(dpos,vector.new(ab.z,ab.y,ab.x)))
							end
						end
					end
				end
			end
		end
    end
})

minetest.register_node("portaltest:structblock",{
    tiles = {"default_steel_block.png^default_obsidian_glass.png"},
    diggable = true,
    groups = {cracky = 1}
})
 
minetest.register_node("portaltest:portalstructure",{
    tiles = {"default_steel_block.png"},
    diggable = false
})

minetest.register_node("portaltest:air",{
	drawtype = "airlike",
	walkable = false,
  pointable = false
})

minetest.register_node("portaltest:portal",{
    drawtype = "liquid",
    tiles = {
        {
            name = "default_water_source_animated.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 2.0,
            },
        },
    },
    walkable = false,
    pointable = false,
    diggable = false
})

minetest.register_node("portaltest:dportal",{
    drawtype = "liquid",
    tiles = {
        {
            name = "default_water_source_animated.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 2.0,
            },
        },
    },
    walkable = false,
    pointable = false,
    diggable = false
})

minetest.register_node("portaltest:controller",{
    tiles = {"default_furnace_bottom.png^default_mese_post_light_side_dark.png^(default_ladder_steel.png^[transform1])^default_obsidian_glass.png"},
	groups ={cracky = 1},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner",placer:get_player_name())
	end,
	can_dig = function(pos,player)
		return default.can_interact_with_node(player,pos)
	end,
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
      local core = minetest.find_node_near(pos, 5, "portaltest:core")
      if core ~= nil then
        formspec(core, player)
      end
    end
})

minetest.register_node("portaltest:core",{
    tiles = {"default_steel_block.png"},
    on_construct = function(pos)
		local formspec_def = 
		"size[8,6]"..
		"list[current_name;fuelslot;3.5,0.5;1,1;]"..
		"list[current_player;main;0,1.75;8,1;]"..
		"list[current_player;main;0,3;8,3;8]"
        local meta = minetest.get_meta(pos)
		meta:set_string("formspec",formspec_def)
        if get_structure("x",pos) then
            meta:set_string("dir","x")
            meta:set_int("complete",1)
        elseif get_structure("z",pos) then
            meta:set_string("dir","z")
            meta:set_int("complete",1)
        else
            meta:set_int("complete",0)
        end
        meta:set_int("active",0)
        local mbpos = vector.multiply(pos_to_mb(pos),16)
        mbpos = vector.subtract(pos,mbpos)
        mbpos = vector.divide(mbpos,4)
        meta:set_string("ownadress",decode(get_mb_id(pos_to_mb(pos)))..pattern2[(math.floor(mbpos.x)*16+math.floor(mbpos.z)*4)+math.floor(mbpos.y)+1]) 
		local inv = meta:get_inventory()
		inv:set_size("fuelslot", 1)
		meta:set_int("fuel",0)
    end ,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner",placer:get_player_name())
	end,
	can_dig = function(pos,player)
		return default.can_interact_with_node(player,pos)
	end,
    diggable = true,
    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        if meta:get_int("complete") == 1 then
            meta:set_int("complete",0)
            destroy_gate(meta:get_string("dir"),pos)
        end
		local inv = meta:get_inventory()
		local stack = inv:get_stack("fuelslot",1)
		minetest.add_item(pos,stack:to_string())
    end,
	allow_metadata_inventory_put = 	function(pos, listname, index, stack, player)
										local meta = minetest.get_meta(pos)
										local inv = meta:get_inventory()
										local stackto = inv:get_stack(listname, index)
										if (stack:get_name() == "portaltest:red_mese" or stack:get_name() == "portaltest:green_mese" or stack:get_name() == "portaltest:blue_mese") and 
										(stackto:is_empty() or stack:get_name() == stackto:get_name()) then
											return stackto:get_free_space()
										else
											return 0
										end
									end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
										return 0
									end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
										if default.can_interact_with_node(player,pos) then
											local meta  = minetest.get_meta(pos)
											local inv   = meta:get_inventory()
											local stack = inv:get_stack(listname,index)
											return stack:get_count()
										else
											return 0
										end
									end,
    groups = {cracky = 1}
})

minetest.register_craftitem("portaltest:blue_mese",{
	description = "Blue Mese",
	inventory_image = "default_blue_mese_crystal.png",
	wield_image = "default_blue_mese_crystal.png"
})

minetest.register_craftitem("portaltest:red_mese",{
	description = "Red Mese",
	inventory_image = "default_red_mese_crystal.png",
	wield_image = "default_red_mese_crystal.png"
})

minetest.register_craftitem("portaltest:green_mese",{
	description = "Green Mese",
	inventory_image = "default_green_mese_crystal.png",
	wield_image = "default_green_mese_crystal.png"
})

minetest.register_abm({
	label = "get rid of portaltest:air",
	nodenames = {"portaltest:air"},
	interval = 1,
	chance = 1,
	action = function(pos)
		minetest.dig_node(pos)
	end
})

minetest.register_abm({
	label = "Mese Purification",
	nodenames = {"default:mese"},
	neighbors = {"group:water"},
	interval = 5,
	chance = 6,
	action = function(pos)
		local rnd = math.random()
		if rnd <= 0.1 then
			minetest.dig_node(pos)
			minetest.add_item(pos,"portaltest:blue_mese")
		elseif rnd <= 0.49 then
			minetest.dig_node(pos)
			if math.random(1,2) == 1 then
				minetest.add_item(pos,"portaltest:green_mese "..math.random(5,8))
			end
		elseif rnd <= 0.98 then
			minetest.dig_node(pos)
			if math.random(1,2) == 1 then
				minetest.add_item(pos,"portaltest:green_mese "..math.random(2,5))
			end
			if math.random(1,4) == 1 then
				minetest.add_item(pos,"portaltest:red_mese "..math.random(1,3))
			end
		end
	end
})

minetest.register_craft({
	output = "portaltest:core",
	recipe = {{"default:steelblock","default:steelblock","default:steelblock"},
			  {"default:steelblock","portaltest:blue_mese","default:steelblock"},
			  {"default:steelblock","default:steelblock","default:steelblock"}}
})

minetest.register_craft({
	output = "portaltest:structblock",
	recipe = {{"default:steelblock","default:steel_ingot","default:steelblock"},
			  {"default:steel_ingot","portaltest:green_mese","default:steel_ingot"},
			  {"default:steelblock","default:steel_ingot","default:steelblock"}}
})

minetest.register_craft({
	output = "portaltest:controller",
	recipe = {{"default:steel_ingot","default:mese_shard","default:steel_ingot"},
			  {"default:steel_ingot","portaltest:red_mese","default:steel_ingot"},
			  {"default:steelblock","default:steelblock","default:steelblock"}}
})

startup() 
