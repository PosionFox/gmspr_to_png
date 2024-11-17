
show_message("conversion will start now, wait for a confirmation popup");

var result = [];
var fileName = file_find_first("*.gmspr", 0);
while(fileName != "")
{
    array_push(result, fileName);
       
    fileName = file_find_next();
}
file_find_close();

for (var i = 0; i < array_length(result); i++)
{
	var spr = convert_gmspr_to_png(result[i]);
	sprite_save_strip(spr, working_directory + result[i]);
}

show_message("conversion complete! (hopefully) now run the bat file");
