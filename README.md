#Scholars@Duke data vis


analysis and code for scholars@duke data visualization challenge

**Goal:** Visualize the geographic spread of collaborations between scholars in the scholars@duke dataset. 

For a detailed look at the code, see the following jupyter notebooks and scripts:

*Data prep/analyses:*

* **preppingData.ipynb** - build a table representing all of the collaborations present in the scholars_publications.csv dataset. Here a collaboration is defined as two scholars working together on a single publication. Thus, each row in the output table will have information for 2 scholars including their IDs and associated buildings/locations. 

* **collaborationStats.ipynb** - some basic summary stats and analyses on the collaboration table created in preppingData.ipynb

* **visualizationPrep.ipynb** - format and process the collaboration table created in preppingData.ipynb in order to get it ready for subsequent visualization scripts

*Visualization*:

* **vis/Maps** - this directory contains the elements used to create the background map. The map elements were created using MapBox Studio Classic.

* **vis/processing** - this directory contains the processing scripts used to make the map and connections shown in the visualization

* **vis/circos** - this directory contains the *circos* configuration files used to make the building2building circular plot shown on visualization

The final visualization was compiled using Adobe Illustrator, with keys, titles and text added

---
## Overview and definitions
Quick overview of processing steps and operational definitions. See code itself for details

### Assigning departments to buildings
* Many departments have offices spread across 2 or more buildings. A given department was assigned to the building that housed the *most* offices for that department

* The dataset ```data/processed/organization_locations.tsv``` contains a row for each unique department. Additional columns indicate the building ID, Address, and Lat/Lon coordinates for the building associated with that department

### Defining Collaborations
* A collaboration was defined as two people working together on a *single* publication. Entries in the ```scholars_publications.csv``` were grouped according unique ```PUBLICATION_URI```. Any publication with 2 or more authors was included in subsequent analyses. For example, a publication like:

>```Kramer W., Smith F., Tyner R. (1968) Kick out the Jams. Journal of the motor city (10), 13```

would yield the following collaborations:

Scholar 1 | Scholar 2
---|---
W. Kramer | F. Smith
W. Kramer | R. Tyner
F. Smith | R. Tyner


### Assigning department to each member of a collaboration
* Each collaboration is composed of 2 scholars. Each scholar has a unique Duke ID number. Using the ``scholars_faculty.csv`` dataset, first try looking up the Duke ID number to find the associated Appt Org BFR. If a given Duke ID has multiple appointments listed, grab the one labeled **Primary**. If there are multiple appointments, but no **Primary**, grab the first appointment listed. 

* If the Duke ID is not found in ``scholars_faculty.csv``, try searching for other authors with the same ``DISPLAY_NAME`` field in the ``scholars_publications.csv``. Grab any *matching authors* Duke ID and try searching for their Appt Org BFR in the ``scholars_faculty.csv`` table. Assign this value to the original author's Appt Org BFR. 

* After all of that, there were still ~40 authors for whom a Appt Org BFR number could not be found. These were assigned manually by looking up each scholar on the scholars@duke website

### Linking Org BFR number to Department Number (and then building location)
* For each Org BFR, see if there is a matching Department Number in the ``organization_locations.csv`` created above. If so, grab the building ID. 

* If not, look up the OrgBFR in the ``SUBDEPARTMENTSPLIT.tsv`` table, and grab the room_department_split_id. Look up that room_department_split_id in the ``ROOMDEPARTMENTSPLIT.tsv`` table and grab the DUKE_NUMBER. Make sure the DUKE_NUMBER matches an existing value in the ``organization_locations.csv`` table. 

* If a DUKE_NUMBER is still not found, grab the associated Duke ID or name, and look up this scholar on scholars@duke website and find their address. Look up their department, and assign them the DUKE_NUMBER associated with that address elsewhere in the table. 

### Link scholars to building
* Now that every scholar has an associated Department Number. Use that value to look up information (address, lat/lon) about the building associated with that Department Number. 

### Get the building names associated with each address
* For every unique building in the collaborations table, grab the address and look up the associated Building Name using `` http://maps.duke.edu/map/accessible.php?id=21#3896``

### Find travel times between every unique building location in the collaborations table
* Use the Google Maps API to go through unique pairs of buildings, and grab the *travel distance* and *travel duration* between the buildings. If the *walking distance* between the buildings is more than 1 mile, recalculate distance and duration using *driving* as the travel mode. 

---


### Calculate the proportion of collaborations as a function of travel duration
* Using bins of 30 sec durations, count how many scholars are within that radius of each other. Out of that total, caclculate how many of them *actually* collaborated together ever. 

---
#Visualization
### Defining unique collaborations
* Go though the collaborations table created above (that shows *everytime* two scholars worked together), and reduce to showing unique collaborations only (with an additional column counting the number of times a particular pair of scholars worked together)

### Remove any collaboration where the distance between the scholars was 0
* Remove collaborations that occurred between two scholars associated with the same building (either same department, or two departments from the same building)

### Remove outlier location
* There collaborations that are associated with '19 TW Alexander Dr' which is fairly remote from the rest of campus/downtown. For the purposes of the visualization, remove these collaborationsf rom the table. These collaborations represent < 1% of the unique collaborations with a distance > 0. 
