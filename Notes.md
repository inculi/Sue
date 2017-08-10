## To Do
### Fixes
Add image logging (filename, datetime_created) so that we can use !identify again.  

### Improvements
Make a names collection to store identities in instead of names.pckl.  

### Features
Allow Sue to send attatchments (audio/images). This will require toying with applescript.

### New commands
!fact : display a depressing piece of trivia (who cares about *fun*facts?)  
!fortune : os.system('fortune')  
!offensive  : os.system('fortune -o')  
!joke : tell a joke (may have to scrape for this and put into mongo).