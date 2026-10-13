/*
    ©2000 Microsoft Corporation. All rights reserved.
*/

var eqClosedPos  = 207;
var eqOpenedPos  = 0;
var eqIsOpen     = false;
var plClosedPos  = 277;
var plOpenedPos  = 488;
var plIsOpen     = false;
var visClosedPos = 33;
var visOpenedPos = 59;
var visIsOpen    = false;
var vidIsPlaying = false;

var widthClosed = 549;
var widthOpened = 760

var speed = 120;

function Init()
{
    pl.setColumnResizeMode( 0, "Stretches" );
    pl.setColumnResizeMode( 1, "AutoSizeData" );
    visEffects.currentEffectType = mediacenter.effectType;
    visEffects.currentPreset = mediacenter.effectPreset;

    vidIsPlaying = (player.OpenState == osMediaOpen) &&
        (player.currentMedia.ImageSourceWidth>0);
    vidIsPlaying ? StartVideo() : EndVideo();
}

function OnClose()
{
    mediacenter.effectType = visEffects.currentEffectType;
    mediacenter.effectPreset = visEffects.currentPreset;
}

function StartVideo()
{
    vidIsPlaying = true;

    if(visIsOpen)
    {
        ToggleVisView();
    }
    else
    {
        visEffects.visible = false;
        vid.visible = true;
    }
}

function EndVideo()
{
    visEffects.visible = true;
    vidIsPlaying =
        vid.visible = false;
}

function ToggleEqView()
{
    if(eqIsOpen)
    {
        sEqEar.moveto(eqClosedPos, sEqEar.top, speed);
        bEqHandle.image = "L_drwr_open_01_default.bmp";
        bEqHandle.hoverImage = "L_drwr_open_02_rollover.bmp";
        bEqHandle.downImage = "L_drwr_open_03_down.bmp";
        bEq.upToolTip = bEqHandle.upToolTip = xEqTt.toolTip;
    }
    else
    {
        sEqView.visible = bEqClose.visible = true;
        sEqEar.moveto(eqOpenedPos, sEqEar.top, speed);
        bEqHandle.image = "L_drwr_close_01_default.bmp";
        bEqHandle.hoverImage = "L_drwr_close_02_rollover.bmp";
        bEqHandle.downImage = "L_drwr_close_03_down.bmp";
        bEq.upToolTip = bEqHandle.upToolTip = xEqTt.value;
    }
    eqIsOpen = !eqIsOpen;
}

function TogglePlView()
{
    if(plIsOpen)
    {
        pl.visible = false;
        sPlEar.moveto(plClosedPos, sPlEar.top, speed);
        bPlHandle.image = "R_drwr_open_01_default.bmp";
        bPlHandle.hoverImage = "R_drwr_open_02_rollover.bmp";
        bPlHandle.downImage = "R_drwr_open_03_down.bmp";
        bPl.upToolTip = bPlHandle.upToolTip = xPlTt.tooltip;
    }
    else
    {
        view.width = widthOpened;
        bPlClose.visible = true;
        sPlEar.moveto(plOpenedPos, sPlEar.top, speed);
        bPlHandle.image = "R_drwr_close_01_default.bmp";
        bPlHandle.hoverImage = "R_drwr_close_02_rollover.bmp";
        bPlHandle.downImage = "R_drwr_close_03_down.bmp";
        bPl.upToolTip = bPlHandle.upToolTip = xPlTt.value;
    }
    plIsOpen = !plIsOpen;
}

function ToggleVisView()
{
    if(visIsOpen)
    {
        visDrop.moveto(visDrop.left, visClosedPos, speed);
        vis.upToolTip = xVisTt.value;
        visIsOpen = false;
    }
    else if(!vidIsPlaying)
    {
        visDrop.visible = true;
        visDrop.moveto(visDrop.left, visOpenedPos, speed);
        vis.upToolTip = xVisTt.value;
        visIsOpen = true;
    }
}

function PlOnEndMove()
{
    pl.visible =
        bPlClose.visible = plIsOpen;
    if(!plIsOpen)
    {
        view.width = widthClosed;
    }
}

function EqOnEndMove()
{
    sEqView.visible =
        bEqClose.visible = eqIsOpen;
}

function VisDropOnEndMove()
{
    visDrop.visible = visIsOpen;
    if(vidIsPlaying)
    {
        StartVideo();
    }
}