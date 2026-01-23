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
	analyser.fftSize = 2048; // Higher for better waveform detail
	source.connect(analyser);

	const canvasCtx = canvasElement.getContext('2d');
	clearCanvas(canvasElement, canvasCtx);

	return { audioContext, analyser, canvasCtx };
}

/**
 * @description     Starts the animation loop for thin waveform
 * @param {AnalyserNode} analyser - Web Audio API analyser node
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @param {Function} isRecordingFn - Function returning current recording state
 */
export function startAnimation(analyser, canvasCtx, canvasElement, isRecordingFn) {
	function animate() {
		if (!isRecordingFn()) return;
		drawWaveform(analyser, canvasCtx, canvasElement);
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
 * @description     Draws thin waveform visualization
 *                  Thinner line with subtle amplitude-based styling
 * @param {AnalyserNode} analyser - Web Audio API analyser node
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @private
 */
function drawWaveform(analyser, canvasCtx, canvasElement) {
	const { width, height } = canvasElement;
	canvasCtx.clearRect(0, 0, width, height);

	const bufferLength = analyser.fftSize;
	const dataArray = new Float32Array(bufferLength);
	analyser.getFloatTimeDomainData(dataArray);

	canvasCtx.lineWidth = 2;
	canvasCtx.strokeStyle = '#00ffcc'; // Cyan color

	canvasCtx.beginPath();

	const sliceWidth = width / bufferLength;
	let x = 0;

	dataArray.forEach((data, i) => {
		const v = data * 0.5 + 0.5; // Normalize to 0-1
		const y = v * height;

		if (i === 0) {
			canvasCtx.moveTo(x, y);
		} else {
			canvasCtx.lineTo(x, y);
		}

		x += sliceWidth;

		// Vary line thickness based on amplitude (subtly)
		const amplitude = Math.abs(data);
		canvasCtx.lineWidth = 1 + amplitude * 3;

		// Change color based on amplitude
		const hue = 180 + amplitude * 180;
		canvasCtx.strokeStyle = `hsl(${hue}, 100%, 50%)`;
	});

	canvasCtx.lineTo(canvasElement.width, canvasElement.height / 2);
	canvasCtx.stroke();
}