
// thanks to YellowAfterLife for this code vvv
function convert_gmspr_to_png(_file)
{
		var gmspr/*:Buffer*/ = buffer_load(_file);
	if (gmspr < 0) return -1;
	if (buffer_read(gmspr, buffer_s32) != 1234321) {
	    buffer_delete(gmspr);
	    return -1;
	}
	var size = buffer_read(gmspr, buffer_s32);
	var compressed/*:Buffer*/ = buffer_create(size, buffer_fixed, 1);
	buffer_copy(gmspr, buffer_tell(gmspr), size, compressed, 0);
	buffer_delete(gmspr);
	var raw/*:Buffer*/ = buffer_decompress(compressed);
	buffer_delete(compressed);
	if (raw < 0) return -1;
	var version = buffer_read(raw, buffer_s32); // we don't really care, it's always 800
	var xorig = buffer_read(raw, buffer_s32);
	var yorig = buffer_read(raw, buffer_s32);
	var count = buffer_read(raw, buffer_s32);
	if (count <= 0) {
	    buffer_delete(raw);
	    return -1;
	}
	var stripsurf/*:Surface*/ = -1;
	var framebuf/*:Buffer*/ = -1;
	var framesurf/*:Surface*/ = -1;
	var width, height, i;
	for (i = 0; i < count; i++) {
	    version = buffer_read(raw, buffer_s32); // we still don't really care
	    width = buffer_read(raw, buffer_s32);
	    height = buffer_read(raw, buffer_s32);
	    size = buffer_read(raw, buffer_s32);
	    if (i == 0) { // initialize things on first call
	        framebuf = buffer_create(size, buffer_fast, 1);
	        if (count > 1) { // make the strip surface if we've multiple frames
	            stripsurf = surface_create(width * count, height);
	            surface_set_target(stripsurf);
	            draw_clear_alpha(0, 0);
	            surface_reset_target();
	        }
	        framesurf = surface_create(width, height);
	        surface_set_target(framesurf);
	        draw_clear_alpha(0, 0);
	        surface_reset_target();
	    }
	    buffer_copy(raw, buffer_tell(raw), size, framebuf, 0);
	    buffer_seek(raw, buffer_seek_relative, size);
	    // fix R/B channels being swapped:
	    for (var k = 0; k < size; k += 4) {
	        var v = buffer_peek(framebuf, k, buffer_u8);
	        buffer_poke(framebuf, k, buffer_u8, buffer_peek(framebuf, k + 2, buffer_u8));
	        buffer_poke(framebuf, k + 2, buffer_u8, v);
	    }
	    buffer_set_surface(framebuf, framesurf, 0);
	    if (count > 1) surface_copy(stripsurf, width * i, 0, framesurf);
	}
	// create the sprite and add the frames to it:
	var spr/*:Sprite*/ = sprite_create_from_surface(
	    count > 1 ? stripsurf : framesurf,
	    0, 0, width, height,  false, false, xorig, yorig);
	for (i = 1; i < count; i++) {
	    sprite_add_from_surface(spr, stripsurf, i * width, 0, width, height, false, false);
	}
	// free up the frame stuff:
	if (count > 1) surface_free(stripsurf);
	surface_free(framesurf);
	buffer_delete(framebuf);
	// set up collision mask:
	var colKind = buffer_read(raw, buffer_s32);
	var colTol = buffer_read(raw, buffer_s32);
	var sepMasks = buffer_read(raw, buffer_s32);
	var bbMode = buffer_read(raw, buffer_s32);
	var bbLeft = buffer_read(raw, buffer_s32);
	var bbRight = buffer_read(raw, buffer_s32);
	var bbBottom = buffer_read(raw, buffer_s32);
	var bbTop = buffer_read(raw, buffer_s32);
	sprite_collision_mask(spr, sepMasks, bbMode, bbLeft, bbTop, bbRight, bbBottom,
	    colKind, colTol);
	// cleanup the data buffer, and done!
	buffer_delete(raw);
	return spr;
}
