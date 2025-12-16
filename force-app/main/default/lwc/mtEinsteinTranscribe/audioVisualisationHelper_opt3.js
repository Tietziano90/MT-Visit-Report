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
	analyser.fftSize = 256;
	source.connect(analyser);

	const canvasCtx = canvasElement.getContext('2d');
	clearCanvas(canvasElement, canvasCtx);

	return { audioContext, analyser, canvasCtx };
}

/**
 * @description     Starts the animation loop for combined visualization
 * @param {AnalyserNode} analyser - Web Audio API analyser node
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @param {Function} isRecordingFn - Function returning current recording state
 */
export function startAnimation(analyser, canvasCtx, canvasElement, isRecordingFn) {
	function animate() {
		if (!isRecordingFn()) return;
		drawCombinedVisualization(analyser, canvasCtx, canvasElement);
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
 * @description     Draws combined visualization with waveform and frequency bars
 *                  Background: subtle gray waveform
 *                  Foreground: colored frequency bars with gradient
 * @param {AnalyserNode} analyser - Web Audio API analyser node
 * @param {CanvasRenderingContext2D} canvasCtx - Canvas 2D context
 * @param {HTMLCanvasElement} canvasElement - Canvas element
 * @private
 */
function drawCombinedVisualization(analyser, canvasCtx, canvasElement) {
	const { width, height } = canvasElement;
	canvasCtx.clearRect(0, 0, width, height);

	// 1. Draw background waveform (subtly)
	const bufferLength = analyser.fftSize;
	const timeDomainData = new Uint8Array(bufferLength);
	analyser.getByteTimeDomainData(timeDomainData);

	canvasCtx.lineWidth = 1;
	canvasCtx.strokeStyle = 'rgba(100, 100, 100, 0.5)'; // Light gray, transparent

	canvasCtx.beginPath();
	const sliceWidthTime = width / bufferLength;
	let xTime = 0;
	for (let i = 0; i < bufferLength; i++) {
		const v = timeDomainData[i] / 128.0; // Normalize to 0-1
		const y = v * height / 2 + height / 4; // Center the waveform
		if (i === 0) {
			canvasCtx.moveTo(xTime, y);
		} else {
			canvasCtx.lineTo(xTime, y);
		}
		xTime += sliceWidthTime;
	}
	canvasCtx.stroke();

	// 2. Draw frequency bars (foreground)
	const dataArray = new Uint8Array(analyser.frequencyBinCount);
	analyser.getByteFrequencyData(dataArray);

	const barWidth = (width / dataArray.length) * 2.5;
	let barHeight;
	let xFreq = 0;

	dataArray.forEach(value => {
		barHeight = value / 3; // Adjust height scaling
		const gradient = canvasCtx.createLinearGradient(0, height - barHeight, 0, height);
		gradient.addColorStop(0, '#007bff'); // Blue
		gradient.addColorStop(1, '#ff6b6b'); // Red

		canvasCtx.fillStyle = gradient;
		canvasCtx.fillRect(xFreq, height - barHeight, barWidth, barHeight);
		xFreq += barWidth + 1;
	});
}