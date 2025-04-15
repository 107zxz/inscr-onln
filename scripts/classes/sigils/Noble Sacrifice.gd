extends SigilEffect

#defines how much extra blood this sigil causes the card to provide.
#Cards that provide 0 or less blood cannot be sacrificed, but can still be hammered.
#Sigil values are added together, so if you want to have a sigil stop sacrificing, use something like -99
func bonus_blood():
	return 1
