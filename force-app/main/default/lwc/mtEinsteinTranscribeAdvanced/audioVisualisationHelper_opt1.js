/*
================================================================================
MT RECORD SUGGESTION - Lightning Web Component
================================================================================
Author: Michael Tietze, Principal AI Architect
Contact: mtietze@salesforce.com
Created: December 2025
Version: 1.5

COPYRIGHT AND DISTRIBUTION
Copyright © 2025 Salesforce, Inc. All rights reserved.

INTERNAL USE ONLY - This code may not be shared externally or distributed
outside of Salesforce without prior written approval from Michael Tietze
(mtietze@salesforce.com).
================================================================================
*/

let animationFrameId = null;

/**
 * @description     Initializes the audio visualization context
 * @param {MediaStream} stream - The audio stream from MediaRecorder
 * @param {HTMLCanvasElement} canvasElement - Canvas element for rendering
 * @returns {Object} Contains audioContext, analyser, and canvasCtx
 */
export function initializeVisualization(stream, canvasElement) {
	if (!canvasElement) {
		throw new Error('Canvas element not found for visualization.');
	}

	const audioContext = new (window.AudioContext || window.webkitAudioContext)();
	const source = audioContext.createMediaStreamSource(stream);
	const analyser = audioContext.createAnalyser();
	analyser.fftSize = 512; // Increase for more detail
	source.connect(analyser);

	const canvasCtx = canvasElement.getContext('2d');
	clearCanvas(canvasElement, canvasCtx);

	return { audioContext, analyser, canvasCtx };
}

/**
 * @description     Starts the animation loop for circular spectrum
 * @param {AnalyserNode} analyser - Web Audio API analyser node
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @param {Function} isRecordingFn - Function returning current recording state
 */
export function startAnimation(analyser, canvasCtx, canvasElement, isRecordingFn) {
	function animate() {
		if (!isRecordingFn()) return;
		drawCircularSpectrum(analyser, canvasCtx, canvasElement);
		animationFrameId = requestAnimationFrame(animate);
	}
	animate();
}

/**
 * @description     Stops the animation loop
 */
export function stopAnimation() {
	if (animationFrameId) {
		cancelAnimationFrame(animationFrameId);
		animationFrameId = null;
	}
}

/**
 * @description     Clears the canvas
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 */
export function clearCanvas(canvasElement, canvasCtx) {
	canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
}

/**
 * @description     Draws circular frequency spectrum visualization
 *                  Bars radiate outward from center, colored by frequency
 * @param {AnalyserNode} analyser - Web Audio API analyser node
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @private
 */
function drawCircularSpectrum(analyser, canvasCtx, canvasElement) {
	const { width, height } = canvasElement;
	const centerX = width / 2;
	const centerY = height / 2;
	const radius = Math.min(width, height) / 3;
	canvasCtx.clearRect(0, 0, width, height);

	const dataArray = new Uint8Array(analyser.frequencyBinCount);
	analyser.getByteFrequencyData(dataArray);

	const numBars = dataArray.length;
	const angleIncrement = (2 * Math.PI) / numBars;

	dataArray.forEach((value, index) => {
		const angle = index * angleIncrement;
		const barHeight = (value / 255) * radius; // Normalize to radius scale

		const x1 = centerX + radius * Math.cos(angle);
		const y1 = centerY + radius * Math.sin(angle);
		const x2 = centerX + (radius + barHeight) * Math.cos(angle);
		const y2 = centerY + (radius + barHeight) * Math.sin(angle);

		canvasCtx.lineWidth = 2;
		canvasCtx.strokeStyle = `hsl(${index / numBars * 360}, 100%, 50%)`;
		canvasCtx.beginPath();
		canvasCtx.moveTo(x1, y1);
		canvasCtx.lineTo(x2, y2);
		canvasCtx.stroke();
	});
}