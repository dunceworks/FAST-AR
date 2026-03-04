# Test blurring and sharpening for near image enhancement

import cv2
import numpy as np

#print working directory
import os
print(os.getcwd())

test_image_path = './FAST-AR/py/test_images/image.png'  # Path to a test image

def blur(image, kernel_size=(5, 5), num_iterations=1):
    """Applies a Gaussian blur to the input image."""
    result = image.copy()
    for _ in range(num_iterations):
        result = cv2.GaussianBlur(result, kernel_size, 0)
    return result


def sharpen(image):
    """Applies a sharpening filter to the input image."""    
    kernel = np.array([[-1, -1, -1],
                       [-1, 9, -1],
                       [-1, -1, -1]])
    return cv2.filter2D(image, -1, kernel)

def grayscale(image):
    """Converts the input image to grayscale."""
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Gray scale edge detection using Sobel operator
def sobel(image):
    """Applies Sobel edge detection to the input image."""
    sobelx = cv2.Sobel(image, cv2.CV_64F, 1, 0, ksize=3)
    sobely = cv2.Sobel(image, cv2.CV_64F, 0, 1, ksize=3)
    sobel_combined = cv2.magnitude(sobelx, sobely)
    return cv2.convertScaleAbs(sobel_combined)

def blarpen(image, num_iterations=1):
    """Applies blarpening (blur + sharpen) to the input image."""
    result = image.copy()
    for _ in range(num_iterations):
        result = sharpen(blur(result))
    return result

def edge_remove(image):
    """Applied after sobel. If at least 5 of 9 pixels are set, remove the pixel."""

    #invert colors
    image = cv2.bitwise_not(image)

    kernel = np.array([[-1, -1, -1],
                       [-1, 9, -1],
                       [-1, -1, -1]])
    
    image = cv2.morphologyEx(image, cv2.MORPH_OPEN, kernel)
    
    #invert colors
    return image #cv2.bitwise_not(image)

# apply to test image
if __name__ == "__main__":
    # Load a test image
    image = grayscale(cv2.imread(test_image_path))

    image_edges = sobel(image)  # Apply edge detection to the original image

    # Apply blurring
    blurred_image = blur(image)

    # Apply sharpening
    sharpened_image = sharpen(image)

    fucked_image = edge_remove(sobel(blur(image, num_iterations=5)))   # Apply blarpening (blur + sharpen)

    # Display the results
    cv2.imshow('Original Image', image_edges)
    cv2.imshow('Blurred Image', blurred_image)
    cv2.imshow('Sharpened Image', sharpened_image)
    cv2.imshow('Fucked Image', fucked_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
