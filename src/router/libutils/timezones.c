/*
 * timezones.c
 *
 * Copyright (C) 2014 Sebastian Gottschall <gottschall@dd-wrt.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id:
 */

#include <utils.h>
#include <stdlib.h>
#include <bcmnvram.h>
#include <timezones.inc>

void update_timezone(void)
{
	char *tz;
	tz = nvram_safe_get("time_zone");	//e.g. EUROPE/BERLIN

	int i;
	int found = 0;
	const char *zone = "Europe/Moscow";
	for (i = 0; allTimezones[i].tz_name != NULL; i++) {
		if (!strcmp(allTimezones[i].tz_name, tz)) {
			zone = allTimezones[i].tz_string;
			found = 1;
			break;
		}
	}
	if (!found)
		nvram_set("time_zone", zone);
	FILE *fp = fopen("/tmp/TZ", "wb");
	fprintf(fp, "%s\n", zone);
	fclose(fp);
	setenv("TZ", zone, 1);
}
