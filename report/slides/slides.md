
# Outline

- Problem Definition
- Related Work
- Our Approach
	* Seam Carving
	* Retargeting via Axis-aligned Deformation
- Results and Evaluation
- Conclusion and Future Work
- Acknowledgement


# Problem Definition --- Image Retargeting
- Objective: Resize an image (without losing important information)
- Input: an image I of size $m \times n$, a new size $m' \times n'$
- Output: a new image $I’$ of size $m' \times n'$
- Requirement: $I'$ should be a good representation of $I$
	* Important content should be reserved
	* Important structure should be reserved
	* New image should be free of _artifacts_

# More about the Problem
- Aspect Ratio = Height / Width
- Two kinds of approaches
	* Content-independent approaches
		- Scaling, Cropping
	* Content-aware approaches
		- Our interests
- Demand for this technique
	* Fixed display regions, layout changes, etc.
	* Widescreen adjustment for movie scenes
	* Auto-fill to PC/Phone screens
- Fun to play with
	* Clean problem, Seeable results, Understandable data and techniques

# Related Work

# Our Approach 1: Seam Carving

# Our Approach 2: Retargeting via Axis-aligned Deformation
- Basic idea
	* The source image is segmented into grids of the same size
	* Each grid is scaled into different sizes based on its importance
- Advantages
	* Robustness
	* No potential foldovers
	* Smoothness
	* Low computation complexity

# Our Approach 2: Axis-aligned Retargeting (cont.)
- How to define importance?
	* An automatically-computed saliency map is used for retargeting
	* Similar to the intensity gradient used in seam carving
- How to formalize the problem?

# Results and Evaluation

# Conclusion

# Road to Solution

# Lessons Learned

# References
- Daniel Vaquero, et al., 2010. A survey of image retargeting techniques.
- Shai Avidan and Ariel Shamir, 2007. ACM Trans. Graph.
- Daniele Panozzo, et al., 2012. Robust Image Retargeting via Axis-Aligned Deformation. Computer Graphics Forum (proceedings of EUROGRAPHICS).


# Acknowledgement


